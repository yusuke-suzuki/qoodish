import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { type ShareNavigator, shareLink } from './shareLink.ts';

const data = { title: 'Ramen map', url: 'https://qoodish.com/maps/1' };

function fakeNavigator(overrides: Partial<ShareNavigator> = {}) {
  const shared: ShareData[] = [];
  const copied: string[] = [];

  const navigator = {
    clipboard: {
      writeText: async (text: string) => {
        copied.push(text);
      }
    } as Clipboard,
    share: async (shareData?: ShareData) => {
      shared.push(shareData ?? {});
    },
    ...overrides
  } satisfies ShareNavigator;

  return { navigator, shared, copied };
}

describe('shareLink', () => {
  it('hands the title and the URL to the share sheet', async () => {
    const { navigator, shared, copied } = fakeNavigator();

    assert.equal(await shareLink(data, navigator), 'shared');
    assert.deepEqual(shared, [data]);
    assert.deepEqual(copied, []);
  });

  it('copies the URL when the browser cannot share', async () => {
    const { navigator, copied } = fakeNavigator({ share: undefined });

    assert.equal(await shareLink(data, navigator), 'copied');
    assert.deepEqual(copied, [data.url]);
  });

  it('copies the URL when the browser cannot share the data', async () => {
    const { navigator, shared, copied } = fakeNavigator({
      canShare: () => false
    });

    assert.equal(await shareLink(data, navigator), 'copied');
    assert.deepEqual(shared, []);
    assert.deepEqual(copied, [data.url]);
  });

  it('reports a dismissed share sheet as cancelled', async () => {
    const { navigator, copied } = fakeNavigator({
      share: async () => {
        throw new DOMException('Share canceled', 'AbortError');
      }
    });

    assert.equal(await shareLink(data, navigator), 'cancelled');
    assert.deepEqual(copied, []);
  });

  it('rethrows any other share failure', async () => {
    const { navigator } = fakeNavigator({
      share: async () => {
        throw new DOMException('Not allowed', 'NotAllowedError');
      }
    });

    await assert.rejects(shareLink(data, navigator), {
      name: 'NotAllowedError'
    });
  });
});
