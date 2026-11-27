const MAX_REPORTS_PER_PAGE = 5;
const MAX_STACK_LENGTH = 4000;
const IDENTIFYING_FIELDS = ['code', 'status', 'type'] as const;
const MAX_LISTED_KEYS = 10;
const IDENTIFIER = /^[A-Za-z_$][\w$]*$/;
const FIELD_VALUE = /^(?=.{1,64}$)[\w.-]+(?:\/[\w.-]+)*$/;
const TYPE_TAG = /^\[object [A-Za-z][\w$]{0,63}\]$/;

// Browsers fire this for layout loops that resolve on the next frame; it is
// not actionable and would crowd out real errors.
const IGNORED_MESSAGE = /ResizeObserver loop/;

let reported = 0;

type ErrorDetail = {
  message: string;
  stack?: string;
  digest?: string;
};

function read(value: object, key: string): unknown {
  try {
    return Reflect.get(value, key);
  } catch {
    return undefined;
  }
}

function readString(value: object, key: string): string | undefined {
  const field = read(value, key);
  return typeof field === 'string' && field !== '' ? field : undefined;
}

function describeObject(value: object): string {
  const fields: Record<string, string | number> = {};

  for (const key of IDENTIFYING_FIELDS) {
    const field = read(value, key);

    if (
      typeof field === 'number' ||
      (typeof field === 'string' && FIELD_VALUE.test(field))
    ) {
      fields[key] = field;
    }
  }

  const ownTag = Object.prototype.toString.call(value);
  const tag = TYPE_TAG.test(ownTag) ? ownTag : '[object Object]';

  if (Object.keys(fields).length > 0) {
    return `${tag} ${JSON.stringify(fields)}`;
  }

  const keys = Object.keys(value)
    .filter((key) => IDENTIFIER.test(key))
    .slice(0, MAX_LISTED_KEYS);

  return keys.length > 0 ? `${tag} with keys ${keys.join(', ')}` : tag;
}

function describeSafely(value: object): string {
  try {
    return describeObject(value);
  } catch {
    return 'Unreadable thrown value';
  }
}

export function detailOf(value: unknown): ErrorDetail {
  if (
    value === null ||
    (typeof value !== 'object' && typeof value !== 'function')
  ) {
    return { message: String(value) };
  }

  return {
    message: readString(value, 'message') ?? describeSafely(value),
    stack: readString(value, 'stack')?.slice(0, MAX_STACK_LENGTH),
    digest: readString(value, 'digest')
  };
}

export default function reportClientError(
  error: unknown,
  source: string
): void {
  console.error(error);

  const detail = detailOf(error);

  if (
    reported >= MAX_REPORTS_PER_PAGE ||
    IGNORED_MESSAGE.test(detail.message)
  ) {
    return;
  }

  reported += 1;

  fetch('/api/errors', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    keepalive: true,
    // The query can carry credentials such as the email sign-in code.
    body: JSON.stringify({
      ...detail,
      source,
      url: location.origin + location.pathname
    })
  }).catch(() => {});
}
