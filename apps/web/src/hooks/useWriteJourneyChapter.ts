'use client';

import { useParams, useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { useState } from 'react';
import { writeJourneyChapter } from '../actions/chapters.ts';
import useDictionary from './useDictionary.ts';

type WriteResult = Awaited<ReturnType<typeof writeJourneyChapter>>;

export default function useWriteJourneyChapter() {
  const dictionary = useDictionary();
  const { lang } = useParams<{ lang: string }>();
  const router = useRouter();
  const [writingId, setWritingId] = useState<number | null>(null);

  const write = async (journeyId: number) => {
    setWritingId(journeyId);

    const { success, data, error } = await writeJourneyChapter(
      journeyId,
      dictionary['untitled chapter']
    ).catch((): WriteResult => ({ success: false }));

    if (!success || !data) {
      enqueueSnackbar(error ?? dictionary['an error occurred'], {
        variant: 'error'
      });
      setWritingId(null);
      return;
    }

    router.push(`/${lang}/chapters/${data.id}/edit`);
  };

  return { writingId, write };
}
