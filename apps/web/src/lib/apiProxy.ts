import { type NextRequest, NextResponse } from 'next/server';
import describeError from '../utils/describeError.ts';
import { LOCALE_COOKIE } from '../utils/locales.ts';
import {
  apiUrl,
  buildApiHeaders,
  DEFAULT_TIMEOUT_MS,
  getAuthToken,
  isTimeoutError,
  resolveApiLanguage
} from './apiRequest.ts';
import {
  getMaintenance,
  maintenanceWriteBlockedMessage
} from './maintenance.ts';

type ProxyOptions = {
  signedIn: boolean;
  withinRateLimit?: () => Promise<boolean>;
};

export async function proxyToApi(
  request: NextRequest,
  path: string,
  { signedIn, withinRateLimit }: ProxyOptions
): Promise<Response> {
  const token = signedIn ? await getAuthToken() : null;

  if (signedIn && !token) {
    return NextResponse.json({ detail: 'Unauthorized' }, { status: 401 });
  }

  const acceptLanguage = resolveApiLanguage({
    rememberedLocale: request.cookies.get(LOCALE_COOKIE)?.value,
    acceptLanguage: request.headers.get('accept-language')
  });

  if (request.method === 'POST' && (await getMaintenance())) {
    return NextResponse.json(
      { detail: maintenanceWriteBlockedMessage(acceptLanguage) },
      { status: 503 }
    );
  }

  if (withinRateLimit && !(await withinRateLimit())) {
    return NextResponse.json(
      { detail: 'Too many uploads' },
      { status: 429, headers: { 'Retry-After': '60' } }
    );
  }

  const init: RequestInit = {
    method: request.method,
    headers: buildApiHeaders({ token, acceptLanguage }),
    signal: AbortSignal.timeout(DEFAULT_TIMEOUT_MS)
  };

  if (request.method === 'POST') {
    init.body = await request.text();
  }

  try {
    const res = await fetch(apiUrl(`${path}${request.nextUrl.search}`), init);
    const body = await res.text();

    return new NextResponse(body, {
      status: res.status,
      headers: {
        'Content-Type': res.headers.get('content-type') ?? 'application/json'
      }
    });
  } catch (error) {
    const timedOut = isTimeoutError(error);

    console.error(
      `Proxy error for ${path} [${timedOut ? 'timeout' : 'network'}]: ${describeError(error)}`
    );

    if (timedOut) {
      return NextResponse.json({ detail: 'Upstream timeout' }, { status: 504 });
    }

    return NextResponse.json(
      { detail: 'Internal proxy error' },
      { status: 502 }
    );
  }
}
