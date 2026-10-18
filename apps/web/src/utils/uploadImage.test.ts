import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import uploadImage, {
  buildVariants,
  MAX_IMAGE_FILE_SIZE,
  splitOversizedImages,
  UPLOAD_RETRY_DELAY_MS,
  UploadRateLimitedError,
  uploadFailureMessage,
  uploadImageWhenAllowed
} from './uploadImage.ts';

describe('uploadImage', () => {
  it('names a refused allocation so the reader is told to wait', async (t) => {
    t.mock.method(
      globalThis,
      'fetch',
      async () => new Response('{}', { status: 429 })
    );

    await assert.rejects(
      uploadImage(new File([], 'a.jpg')),
      UploadRateLimitedError
    );
  });
});

const CLOUDFLARE_VARIANTS = ['avatar', 'card', 'hero', 'ogp', 'public'].map(
  (name) => `https://imagedelivery.net/hash/image-1/${name}`
);

function respondInTurn(responses: Response[]) {
  return async () => responses.shift() ?? new Response('{}', { status: 500 });
}

const allocated = () =>
  Response.json({ upload_url: 'https://upload.example/1', id: 7 });

const stored = () =>
  Response.json({
    success: true,
    result: { id: 'image-1', variants: CLOUDFLARE_VARIANTS }
  });

const refused = () => new Response('{}', { status: 429 });

describe('uploadImageWhenAllowed', () => {
  it('waits out a refused allocation and uploads once allowed', async (t) => {
    t.mock.method(
      globalThis,
      'fetch',
      respondInTurn([refused(), refused(), allocated(), stored()])
    );
    const waits: number[] = [];

    const image = await uploadImageWhenAllowed(
      new File([], 'a.jpg'),
      async (ms) => waits.push(ms)
    );

    assert.equal(image.id, 7);
    assert.deepEqual(waits, [UPLOAD_RETRY_DELAY_MS, UPLOAD_RETRY_DELAY_MS]);
  });

  it('gives up after six waits', async (t) => {
    t.mock.method(globalThis, 'fetch', async () => refused());
    const waits: number[] = [];

    await assert.rejects(
      uploadImageWhenAllowed(new File([], 'a.jpg'), async (ms) =>
        waits.push(ms)
      ),
      UploadRateLimitedError
    );
    assert.equal(waits.length, 6);
  });

  it('does not retry any other failure', async (t) => {
    t.mock.method(
      globalThis,
      'fetch',
      async () => new Response('{}', { status: 500 })
    );
    const waits: number[] = [];

    await assert.rejects(
      uploadImageWhenAllowed(new File([], 'a.jpg'), async (ms) =>
        waits.push(ms)
      ),
      /Failed to allocate upload URL/
    );
    assert.deepEqual(waits, []);
  });
});

describe('uploadFailureMessage', () => {
  const dictionary = {
    'upload rate limited': 'wait',
    'an error occurred': 'error'
  };

  it('tells a rate limit apart from any other failure', () => {
    assert.equal(
      uploadFailureMessage(new UploadRateLimitedError(), dictionary),
      'wait'
    );
    assert.equal(uploadFailureMessage(new Error('x'), dictionary), 'error');
  });
});

const DELIVERY_BASE = 'https://imagedelivery.net/hash/image-1';

function fileOfSize(bytes: number, name: string): File {
  return new File([new Uint8Array(bytes)], name, { type: 'image/jpeg' });
}

describe('splitOversizedImages', () => {
  it('keeps files at the limit and rejects files above it', () => {
    const atLimit = fileOfSize(MAX_IMAGE_FILE_SIZE, 'ok.jpg');
    const aboveLimit = fileOfSize(MAX_IMAGE_FILE_SIZE + 1, 'big.jpg');

    const { accepted, oversized } = splitOversizedImages([atLimit, aboveLimit]);

    assert.deepEqual(accepted, [atLimit]);
    assert.deepEqual(oversized, [aboveLimit]);
  });

  it('preserves the selection order among accepted files', () => {
    const first = fileOfSize(1, 'first.jpg');
    const second = fileOfSize(2, 'second.jpg');

    assert.deepEqual(splitOversizedImages([first, second]).accepted, [
      first,
      second
    ]);
  });
});

function variantUrls(names: string[]): string[] {
  return names.map((name) => `${DELIVERY_BASE}/${name}`);
}

describe('buildVariants', () => {
  it('maps Cloudflare variant names onto the API image keys', () => {
    const urls = variantUrls(['avatar', 'card', 'hero', 'ogp', 'public']);

    assert.deepEqual(buildVariants(urls), {
      url: `${DELIVERY_BASE}/public`,
      avatar: `${DELIVERY_BASE}/avatar`,
      card: `${DELIVERY_BASE}/card`,
      hero: `${DELIVERY_BASE}/hero`,
      ogp: `${DELIVERY_BASE}/ogp`
    });
  });

  it('ignores extra variants Cloudflare may add', () => {
    const urls = variantUrls([
      'avatar',
      'card',
      'hero',
      'ogp',
      'public',
      'thumbnail'
    ]);

    assert.equal(buildVariants(urls).url, `${DELIVERY_BASE}/public`);
  });

  it('rejects a response missing a configured variant', () => {
    const urls = variantUrls(['avatar', 'card', 'hero', 'public']);

    assert.throws(() => buildVariants(urls), /"ogp" is not configured/);
  });

  it('rejects a response missing the built-in public variant', () => {
    const urls = variantUrls(['avatar', 'card', 'hero', 'ogp']);

    assert.throws(() => buildVariants(urls), /"public" is not configured/);
  });
});
