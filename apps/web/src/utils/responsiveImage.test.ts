import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { responsiveImage } from './responsiveImage.ts';

const base = 'https://imagedelivery.net/hash/qoodish/photo';

const image = {
  url: `${base}/public`,
  avatar: `${base}/avatar`,
  card: `${base}/card`,
  hero: `${base}/hero`,
  ogp: `${base}/ogp`
};

describe('responsiveImage', () => {
  it('offers every variant wide enough for a card, smallest first', () => {
    assert.deepEqual(responsiveImage(image, '50vw'), {
      src: `${base}/card`,
      srcSet: `${base}/card 400w, ${base}/hero 800w, ${base}/public 2048w`,
      sizes: '50vw'
    });
  });
});
