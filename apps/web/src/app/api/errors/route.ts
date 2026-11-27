import { CLIENT_ERROR_MAX_BYTES } from '../../../utils/clientErrorReport.ts';

type ClientErrorReport = {
  message: string;
  stack?: string;
  digest?: string;
  url?: string;
  source?: string;
};

// request.text() would buffer the whole body before any check could run, so
// the stream is counted chunk by chunk and dropped once it passes the limit.
async function readBodyWithinLimit(request: Request): Promise<string | null> {
  if (Number(request.headers.get('content-length')) > CLIENT_ERROR_MAX_BYTES) {
    return null;
  }

  const reader = request.body?.getReader();

  if (!reader) {
    return '';
  }

  const decoder = new TextDecoder();
  let received = 0;
  let text = '';

  for (;;) {
    const { done, value } = await reader.read();

    if (done) {
      break;
    }

    received += value.byteLength;

    if (received > CLIENT_ERROR_MAX_BYTES) {
      await reader.cancel();
      return null;
    }

    text += decoder.decode(value, { stream: true });
  }

  return text + decoder.decode();
}

// Workers Issues signs an error with its message and top stack frame. The
// browser's frames name chunk files that change with every deploy, so the
// logged error carries the message alone.
function clientError(message: string): Error {
  const title =
    message.trim() === '' ? 'Client error without a message' : message;
  const error = new Error(title);
  error.stack = `Error: ${title}`;
  return error;
}

export async function POST(request: Request) {
  const origin = request.headers.get('origin');

  // The Origin check only stops cross-site browsers; a scripted caller is
  // bounded by the WAF rate limiting rule on this path.
  if (origin && origin !== new URL(request.url).origin) {
    return new Response(null, { status: 403 });
  }

  const body = await readBodyWithinLimit(request);

  if (body === null) {
    return new Response(null, { status: 413 });
  }

  let report: ClientErrorReport;

  try {
    report = JSON.parse(body);
  } catch {
    return new Response(null, { status: 400 });
  }

  if (typeof report?.message !== 'string') {
    return new Response(null, { status: 400 });
  }

  console.error(clientError(report.message));

  // Same shape as the server-side error line, so one query covers both.
  console.log(
    JSON.stringify({
      kind: 'client-error',
      message: report.message,
      stack_trace: report.stack,
      digest: report.digest,
      url: report.url,
      source: report.source,
      userAgent: request.headers.get('user-agent')
    })
  );

  return new Response(null, { status: 204 });
}
