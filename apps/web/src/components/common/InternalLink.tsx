'use client';

import { Link } from '@mui/material';
import type { ReactNode } from 'react';
import RouterLink from './Link.tsx';

type Props = {
  href: string;
  children: ReactNode;
};

export default function InternalLink({ href, children }: Props) {
  return (
    <Link component={RouterLink} href={href}>
      {children}
    </Link>
  );
}
