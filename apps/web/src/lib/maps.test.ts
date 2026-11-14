import assert from 'node:assert/strict';
import { beforeEach, describe, it, mock } from 'node:test';

const apiFetch = mock.fn(async () => ({
  data: { id: 1 },
  error: null,
  status: 200
}));
const apiFetchList = mock.fn(async () => []);
const cachePublic = mock.fn(async () => {});

mock.module(new URL('./api.ts', import.meta.url).href, {
  namedExports: { apiFetch, apiFetchList, assertApiAvailable: () => {} }
});
mock.module(new URL('./publicCache.ts', import.meta.url).href, {
  namedExports: { cachePublic }
});

const maps = () => import('./maps.ts');

beforeEach(() => {
  apiFetch.mock.resetCalls();
  apiFetchList.mock.resetCalls();
  cachePublic.mock.resetCalls();
});

describe('getMap', () => {
  it('serves a guest from the public cache', async () => {
    const { getMap } = await maps();

    await getMap('1', 'ja');

    assert.deepEqual(apiFetch.mock.calls[0].arguments, [
      '/maps/1',
      { lang: 'ja', guest: true }
    ]);
    assert.deepEqual(cachePublic.mock.calls[0].arguments, [
      300,
      ['map:1', 'content']
    ]);
  });

  it('asks the API as the signed-in viewer without caching', async () => {
    const { getMap } = await maps();

    await getMap('1', 'ja', 'token-1');

    assert.deepEqual(apiFetch.mock.calls[0].arguments, [
      '/maps/1',
      { lang: 'ja', guest: false }
    ]);
    assert.equal(cachePublic.mock.callCount(), 0);
  });
});

describe('getMapPins', () => {
  it('serves a guest from the public cache', async () => {
    const { getMapPins } = await maps();

    await getMapPins('1', 'ja');

    assert.deepEqual(apiFetchList.mock.calls[0].arguments, [
      '/maps/1/pins',
      { lang: 'ja', guest: true }
    ]);
    assert.equal(cachePublic.mock.callCount(), 1);
  });

  it('asks the API as the signed-in viewer without caching', async () => {
    const { getMapPins } = await maps();

    await getMapPins('1', 'ja', 'token-1');

    assert.deepEqual(apiFetchList.mock.calls[0].arguments, [
      '/maps/1/pins',
      { lang: 'ja', guest: false }
    ]);
    assert.equal(cachePublic.mock.callCount(), 0);
  });
});
