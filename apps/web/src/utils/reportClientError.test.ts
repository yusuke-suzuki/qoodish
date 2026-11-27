import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { CLIENT_ERROR_MAX_BYTES } from './clientErrorReport.ts';
import { detailOf, reportBody } from './reportClientError.ts';

describe('detailOf', () => {
  it('takes the message and stack of an error', () => {
    const error = new TypeError('x is not a function');

    assert.deepEqual(detailOf(error), {
      message: 'x is not a function',
      stack: error.stack,
      digest: undefined
    });
  });

  it('takes the digest of a server error', () => {
    const error = Object.assign(new Error('Render failed'), {
      digest: '123456'
    });

    assert.equal(detailOf(error).digest, '123456');
  });

  it('reads an error from another realm by its fields', () => {
    const error = {
      message: 'Popup closed',
      stack: 'Error: Popup closed\n    at popup.js:1:1'
    };

    assert.deepEqual(detailOf(error), {
      message: 'Popup closed',
      stack: 'Error: Popup closed\n    at popup.js:1:1',
      digest: undefined
    });
  });

  it('names an error without a message by its type and code', () => {
    const error = Object.assign(new Error(), {
      code: 'auth/network-request-failed'
    });

    assert.equal(
      detailOf(error).message,
      '[object Error] {"code":"auth/network-request-failed"}'
    );
  });

  it('takes the message of an object that carries one', () => {
    assert.equal(
      detailOf({ code: 'permission-denied', message: 'Missing permissions' })
        .message,
      'Missing permissions'
    );
  });

  it('names an object by its identifying fields', () => {
    assert.equal(
      detailOf({ code: 'unavailable', status: 503 }).message,
      '[object Object] {"code":"unavailable","status":503}'
    );
  });

  it('leaves out the values of other fields', () => {
    const { message } = detailOf({
      code: 'expired',
      name: 'Taro Yamada',
      idToken: 'secret-token'
    });

    assert.doesNotMatch(message, /Taro Yamada|secret-token/);
  });

  it('lists the keys of an object without identifying fields', () => {
    assert.equal(
      detailOf({ idToken: 'secret-token', retry: true }).message,
      '[object Object] with keys idToken, retry'
    );
  });

  it('leaves out keys that are not identifiers', () => {
    assert.equal(
      detailOf({ 'someone@example.com': {}, retry: true }).message,
      '[object Object] with keys retry'
    );
  });

  it('leaves out a type tag that is not an identifier', () => {
    assert.equal(
      detailOf({ [Symbol.toStringTag]: 'someone@example.com' }).message,
      '[object Object]'
    );
  });

  it('names an event by its type', () => {
    assert.equal(
      detailOf(new Event('error')).message,
      '[object Event] {"type":"error"}'
    );
  });

  it('keeps a string as it is', () => {
    assert.deepEqual(detailOf('Load failed'), { message: 'Load failed' });
  });

  it('renders undefined', () => {
    assert.deepEqual(detailOf(undefined), { message: 'undefined' });
  });

  it('keeps the fields that can be read when a getter throws', () => {
    const error = new Error('boom');
    Object.defineProperty(error, 'stack', {
      get() {
        throw new Error('getter');
      }
    });

    assert.deepEqual(detailOf(error), {
      message: 'boom',
      stack: undefined,
      digest: undefined
    });
  });

  it('leaves out a field value that is not an identifier', () => {
    assert.equal(
      detailOf({ type: 'someone@example.com', code: 'expired' }).message,
      '[object Object] {"code":"expired"}'
    );
  });

  it('keeps a code with a namespace', () => {
    assert.equal(
      detailOf({ code: 'auth/network-request-failed' }).message,
      '[object Object] {"code":"auth/network-request-failed"}'
    );
  });

  it('leaves out a field value shaped like a url', () => {
    assert.equal(
      detailOf({ type: 'https://qoodish.com/ja/login/abc123', status: 401 })
        .message,
      '[object Object] {"status":401}'
    );
  });

  it('does not throw for an object whose keys cannot be listed', () => {
    const { proxy, revoke } = Proxy.revocable({}, {});
    revoke();

    assert.equal(detailOf(proxy).message, 'Unreadable thrown value');
  });

  it('keeps the stack of an object whose keys cannot be listed', () => {
    const value = new Proxy(
      { stack: 'at f' },
      {
        ownKeys() {
          throw new Error('trap');
        }
      }
    );

    assert.deepEqual(detailOf(value), {
      message: 'Unreadable thrown value',
      stack: 'at f',
      digest: undefined
    });
  });

  it('does not throw for a message that is not a string', () => {
    const error = Object.assign(new Error('boom'), { message: undefined });

    assert.equal(detailOf(error).message, '[object Error]');
  });

  it('does not throw for an object without a prototype', () => {
    assert.equal(detailOf(Object.create(null)).message, '[object Object]');
  });
});

describe('reportBody', () => {
  const url = 'https://qoodish.com/ja/maps/1';

  it('carries the detail, source and url', () => {
    assert.deepEqual(
      JSON.parse(
        reportBody({ message: 'Load failed', stack: 'at f' }, 'window', url) ??
          ''
      ),
      { message: 'Load failed', stack: 'at f', source: 'window', url }
    );
  });

  it('cuts a long message', () => {
    const body = reportBody({ message: 'x'.repeat(5000) }, 'window', url);

    assert.equal(JSON.parse(body ?? '').message.length, 1000);
  });

  it('cuts only the excess of the stack', () => {
    const stack = 'x'.repeat(4000);
    const message = 'x'.repeat(1000);
    const longest = reportBody({ message, stack }, 'window', url) ?? '';
    const overLimit = reportBody(
      { message, stack: stack.repeat(2) },
      'window',
      url
    );

    assert.equal(
      new TextEncoder().encode(overLimit ?? '').byteLength,
      CLIENT_ERROR_MAX_BYTES
    );
    assert.ok(
      JSON.parse(overLimit ?? '').stack.length >
        JSON.parse(longest).stack.length
    );
  });

  it('keeps as much of a multibyte stack as fits', () => {
    const stack = `Error: ${'あ'.repeat(4000)}`;
    const body =
      reportBody({ message: 'あ'.repeat(1000), stack }, 'window', url) ?? '';
    const sent: string = JSON.parse(body).stack;
    const longer = JSON.stringify({
      ...JSON.parse(body),
      stack: stack.slice(0, sent.length + 1)
    });

    assert.ok(sent.length > 0 && stack.startsWith(sent));
    assert.ok(
      new TextEncoder().encode(body).byteLength <= CLIENT_ERROR_MAX_BYTES
    );
    assert.ok(
      new TextEncoder().encode(longer).byteLength > CLIENT_ERROR_MAX_BYTES
    );
  });

  it('keeps the longest stack of whole characters that fits', () => {
    const body =
      reportBody(
        { message: 'm'.repeat(977), stack: '😀'.repeat(2000) },
        'error',
        'https://example.com/'
      ) ?? '';

    assert.equal(JSON.parse(body).stack.length, 3572);
  });

  it('keeps an unpaired surrogate that fits', () => {
    const loneSurrogate = String.fromCharCode(0xd800);
    const stack = `${'😀'.repeat(1800)}${loneSurrogate}${'b'.repeat(399)}`;
    const kept = stack.slice(0, 3601);
    const source = 'error';
    const url = 'https://example.com/';
    const overhead = new TextEncoder().encode(
      JSON.stringify({ message: '', stack: kept, source, url })
    ).byteLength;
    const message = 'm'.repeat(CLIENT_ERROR_MAX_BYTES - overhead);

    const body = reportBody({ message, stack }, source, url) ?? '';

    assert.equal(JSON.parse(body).stack, kept);
  });

  it('cuts a long digest', () => {
    const body = reportBody(
      { message: 'x', digest: 'd'.repeat(9000) },
      'window',
      url
    );

    assert.equal(JSON.parse(body ?? '').digest.length, 100);
  });

  it('cuts a long url', () => {
    const body = reportBody(
      { message: 'x' },
      'window',
      `${url}/${'a'.repeat(9000)}`
    );

    assert.equal(JSON.parse(body ?? '').url.length, 2000);
  });
});
