import assert from 'node:assert/strict';
import { beforeEach, describe, it, mock } from 'node:test';
import { POST } from './route.ts';

function report(body: unknown, origin = 'https://qoodish.com') {
  return new Request('https://qoodish.com/api/errors', {
    method: 'POST',
    headers: {
      origin,
      'content-type': 'application/json',
      'user-agent': 'TestBrowser/1.0'
    },
    body: typeof body === 'string' ? body : JSON.stringify(body)
  });
}

beforeEach(() => {
  mock.restoreAll();
});

describe('POST /api/errors', () => {
  it('logs the reported message as an error of its own', async () => {
    const errors = mock.method(console, 'error', () => {});
    mock.method(console, 'log', () => {});

    const res = await POST(
      report({
        message: 'Script error.',
        stack: 'at f (https://qoodish.com/_next/static/chunks/abc123.js:1:2)',
        url: 'https://qoodish.com/en/maps/1',
        source: 'global-error'
      })
    );
    const [logged] = errors.mock.calls[0].arguments;

    assert.equal(res.status, 204);
    assert.equal(errors.mock.callCount(), 1);
    assert.ok(logged instanceof Error);
    assert.equal(logged.message, 'Script error.');
    assert.doesNotMatch(String(logged.stack), /chunks/);
  });

  it('keeps the details of the report in a separate log line', async () => {
    mock.method(console, 'error', () => {});
    const logs = mock.method(console, 'log', () => {});

    await POST(
      report({
        message: 'Load failed',
        stack: 'at g (https://qoodish.com/_next/static/chunks/def456.js:3:4)',
        url: 'https://qoodish.com/ja',
        source: 'window-error'
      })
    );

    assert.deepEqual(JSON.parse(logs.mock.calls[0].arguments[0]), {
      kind: 'client-error',
      message: 'Load failed',
      stack_trace:
        'at g (https://qoodish.com/_next/static/chunks/def456.js:3:4)',
      url: 'https://qoodish.com/ja',
      source: 'window-error',
      userAgent: 'TestBrowser/1.0'
    });
  });

  it('titles a report with an empty message', async () => {
    const errors = mock.method(console, 'error', () => {});
    mock.method(console, 'log', () => {});

    await POST(report({ message: '', source: 'unhandledrejection' }));

    assert.equal(
      errors.mock.calls[0].arguments[0].message,
      'Client error without a message'
    );
  });

  it('refuses a report from another origin', async () => {
    const errors = mock.method(console, 'error', () => {});

    const res = await POST(report({ message: 'x' }, 'https://evil.example'));

    assert.equal(res.status, 403);
    assert.equal(errors.mock.callCount(), 0);
  });

  it('refuses a report over 8 KB', async () => {
    const errors = mock.method(console, 'error', () => {});

    const res = await POST(report({ message: 'x'.repeat(9 * 1024) }));

    assert.equal(res.status, 413);
    assert.equal(errors.mock.callCount(), 0);
  });

  it('refuses a body that is not JSON', async () => {
    const errors = mock.method(console, 'error', () => {});

    const res = await POST(report('not json'));

    assert.equal(res.status, 400);
    assert.equal(errors.mock.callCount(), 0);
  });

  it('logs nothing for a report without a message', async () => {
    const errors = mock.method(console, 'error', () => {});

    const res = await POST(report({ url: 'https://qoodish.com/en' }));

    assert.equal(res.status, 400);
    assert.equal(errors.mock.callCount(), 0);
  });
});
