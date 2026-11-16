import type { ImageVariants } from '../../types/index.ts';

const CARD_WIDTH = 400;
const HERO_WIDTH = 800;
const ORIGINAL_WIDTH = 2048;

export const CARD_GRID_SIZES =
  '(min-width: 1200px) 376px, (min-width: 600px) 50vw, 100vw';

export const PIN_GRID_SIZES =
  '(min-width: 1200px) 276px, (min-width: 900px) 25vw, (min-width: 600px) 33vw, 50vw';

export type ResponsiveImageProps = {
  src: string;
  srcSet: string;
  sizes: string;
};

export function responsiveImage(
  image: ImageVariants,
  sizes: string
): ResponsiveImageProps {
  return {
    src: image.card,
    srcSet: [
      `${image.card} ${CARD_WIDTH}w`,
      `${image.hero} ${HERO_WIDTH}w`,
      `${image.url} ${ORIGINAL_WIDTH}w`
    ].join(', '),
    sizes
  };
}
