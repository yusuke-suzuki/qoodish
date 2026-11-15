'use client';

import NextLink from 'next/link';
import type { ComponentProps } from 'react';

// vinext 1.4.5 with cacheComponents makes a click wait for the link's
// prefetch, which renders the whole page, so loading.tsx never shows.
export default function Link(props: ComponentProps<typeof NextLink>) {
  return <NextLink prefetch={false} {...props} />;
}
