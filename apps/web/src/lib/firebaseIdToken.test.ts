import assert from 'node:assert/strict';
import { beforeEach, describe, it, mock } from 'node:test';
import { exportJWK, generateKeyPair, type JWK, SignJWT } from 'jose';

const PROJECT_ID = 'qoodish-test';

const { verifiedUid } = await import('./firebaseIdToken.ts');

async function signingKey(kid: string) {
  const { privateKey, publicKey } = await generateKeyPair('RS256');
  const jwk: JWK = { ...(await exportJWK(publicKey)), kid, alg: 'RS256' };

  return {
    jwk,
    sign: (claims: { aud?: string; exp?: string } = {}) =>
      new SignJWT({})
        .setProtectedHeader({ alg: 'RS256', kid })
        .setIssuer(`https://securetoken.google.com/${PROJECT_ID}`)
        .setAudience(claims.aud ?? PROJECT_ID)
        .setSubject('user-1')
        .setIssuedAt()
        .setExpirationTime(claims.exp ?? '1h')
        .sign(privateKey)
  };
}

function serveKeys(...keys: JWK[]) {
  return mock.method(
    globalThis,
    'fetch',
    async () =>
      new Response(JSON.stringify({ keys }), {
        headers: { 'cache-control': 'public, max-age=3600' }
      })
  );
}

let now = 1_800_000_000_000;

beforeEach(() => {
  mock.restoreAll();
  mock.timers.reset();
  now += 24 * 60 * 60 * 1000;
  mock.timers.enable({ apis: ['Date'], now });
});

describe('verifiedUid', () => {
  it('gives the subject of a token Firebase signed for the project', async () => {
    const key = await signingKey('a');
    serveKeys(key.jwk);

    assert.equal(await verifiedUid(await key.sign(), PROJECT_ID), 'user-1');
  });

  it('rejects a token issued for another project', async () => {
    const key = await signingKey('b');
    serveKeys(key.jwk);

    assert.equal(
      await verifiedUid(await key.sign({ aud: 'other' }), PROJECT_ID),
      null
    );
  });

  it('rejects an expired token', async () => {
    const key = await signingKey('c');
    serveKeys(key.jwk);

    assert.equal(
      await verifiedUid(await key.sign({ exp: '-1m' }), PROJECT_ID),
      null
    );
  });

  it('rejects a token signed by a key Firebase does not publish', async () => {
    const published = await signingKey('d');
    const forged = await signingKey('d');
    serveKeys(published.jwk);

    assert.equal(await verifiedUid(await forged.sign(), PROJECT_ID), null);
  });

  it('rejects every token without a project id', async () => {
    const key = await signingKey('e');
    serveKeys(key.jwk);

    assert.equal(await verifiedUid(await key.sign(), undefined), null);
  });

  it('reuses fetched keys until they expire', async () => {
    const key = await signingKey('f');
    const fetch = serveKeys(key.jwk);
    const token = await key.sign();

    await verifiedUid(token, PROJECT_ID);
    mock.timers.tick(3_599_000);
    await verifiedUid(token, PROJECT_ID);

    assert.equal(fetch.mock.callCount(), 1);
  });

  it('makes its own fetch while another caller’s fetch is pending', async () => {
    const key = await signingKey('g');
    const { promise: stalled, resolve } = Promise.withResolvers<Response>();
    const responses = [
      stalled,
      Promise.resolve(new Response(JSON.stringify({ keys: [key.jwk] })))
    ];
    const fetch = mock.method(globalThis, 'fetch', () => responses.shift());
    const token = await key.sign();

    const first = verifiedUid(token, PROJECT_ID);

    assert.equal(await verifiedUid(token, PROJECT_ID), 'user-1');
    assert.equal(fetch.mock.callCount(), 2);

    resolve(new Response(JSON.stringify({ keys: [key.jwk] })));
    assert.equal(await first, 'user-1');
  });

  it('fetches the keys again for a key id it has not seen', async () => {
    const old = await signingKey('h');
    const rotated = await signingKey('i');
    serveKeys(old.jwk);
    await verifiedUid(await old.sign(), PROJECT_ID);

    mock.timers.tick(60_000);
    const fetch = serveKeys(old.jwk, rotated.jwk);

    assert.equal(await verifiedUid(await rotated.sign(), PROJECT_ID), 'user-1');
    assert.equal(fetch.mock.callCount(), 1);
  });

  it('fetches the keys at most once a minute for unknown key ids', async () => {
    const known = await signingKey('j');
    const unknown = await signingKey('k');
    serveKeys(known.jwk);
    await verifiedUid(await known.sign(), PROJECT_ID);

    const fetch = serveKeys(known.jwk);

    assert.equal(await verifiedUid(await unknown.sign(), PROJECT_ID), null);
    assert.equal(fetch.mock.callCount(), 0);
  });

  it('keeps verifying with the previous keys when a refetch fails', async () => {
    const key = await signingKey('l');
    serveKeys(key.jwk);
    await verifiedUid(await key.sign(), PROJECT_ID);

    mock.timers.tick(3_600_000);
    mock.restoreAll();
    mock.method(console, 'error', () => {});
    const fetch = mock.method(
      globalThis,
      'fetch',
      async () => new Response('unavailable', { status: 503 })
    );

    assert.equal(await verifiedUid(await key.sign(), PROJECT_ID), 'user-1');
    assert.equal(fetch.mock.callCount(), 1);
  });

  it('does not keep a response that holds no key set', async () => {
    const key = await signingKey('m');
    mock.method(console, 'error', () => {});
    mock.method(globalThis, 'fetch', async () => Response.json({}));

    assert.equal(await verifiedUid(await key.sign(), PROJECT_ID), null);

    const fetch = serveKeys(key.jwk);

    assert.equal(await verifiedUid(await key.sign(), PROJECT_ID), 'user-1');
    assert.equal(fetch.mock.callCount(), 1);
  });

  it('keeps the newer keys when an older fetch finishes last', async () => {
    const old = await signingKey('n');
    const current = await signingKey('o');
    const { promise: stalled, resolve } = Promise.withResolvers<Response>();
    const responses = [
      stalled,
      Promise.resolve(Response.json({ keys: [current.jwk] }))
    ];
    mock.method(globalThis, 'fetch', () => responses.shift());
    const token = await current.sign();

    const first = verifiedUid(token, PROJECT_ID);
    assert.equal(await verifiedUid(token, PROJECT_ID), 'user-1');

    resolve(Response.json({ keys: [old.jwk] }));
    assert.equal(await first, 'user-1');

    const fetch = serveKeys(old.jwk);

    assert.equal(await verifiedUid(token, PROJECT_ID), 'user-1');
    assert.equal(fetch.mock.callCount(), 0);
  });

  it('tries a key rotation at most once a minute even when it fails', async () => {
    const known = await signingKey('p');
    const unknown = await signingKey('q');
    serveKeys(known.jwk);
    await verifiedUid(await known.sign(), PROJECT_ID);

    mock.timers.tick(60_000);
    mock.restoreAll();
    mock.method(console, 'error', () => {});
    const fetch = mock.method(
      globalThis,
      'fetch',
      async () => new Response('unavailable', { status: 503 })
    );
    const token = await unknown.sign();

    assert.equal(await verifiedUid(token, PROJECT_ID), null);
    assert.equal(await verifiedUid(token, PROJECT_ID), null);
    assert.equal(fetch.mock.callCount(), 1);
  });

  it('keeps the previous keys when the endpoint answers a malformed key set', async () => {
    const key = await signingKey('r');
    serveKeys(key.jwk);
    await verifiedUid(await key.sign(), PROJECT_ID);

    mock.timers.tick(3_600_000);
    mock.restoreAll();
    const logged = mock.method(console, 'error', () => {});
    mock.method(globalThis, 'fetch', async () =>
      Response.json({ keys: [null] })
    );

    assert.equal(await verifiedUid(await key.sign(), PROJECT_ID), 'user-1');
    assert.equal(logged.mock.callCount(), 1);
  });
});
