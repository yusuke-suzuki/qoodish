'use client';

import { Alert, Link } from '@mui/material';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalePath from '../../hooks/useLocalePath.ts';
import RouterLink from '../common/Link.tsx';

type Props = {
  date: string;
};

export default function PreviousTermsNotice({ date }: Props) {
  const dictionary = useDictionary();
  const localePath = useLocalePath();

  return (
    <Alert severity="info" sx={{ mb: 3 }}>
      {dictionary['previous terms notice'].replace('{date}', date)}{' '}
      <Link component={RouterLink} href={localePath('/terms')} color="inherit">
        {dictionary['view latest terms']}
      </Link>
    </Alert>
  );
}
