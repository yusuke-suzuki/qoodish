'use client';

import { enqueueSnackbar } from 'notistack';
import { type ShareLinkData, shareLink } from '../utils/shareLink.ts';
import useDictionary from './useDictionary.ts';

export default function useShare() {
  const dictionary = useDictionary();

  return async (data: ShareLinkData) => {
    try {
      const outcome = await shareLink(data, navigator);

      if (outcome === 'copied') {
        enqueueSnackbar(dictionary['link copied'], { variant: 'info' });
      }
    } catch {
      enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
    }
  };
}
