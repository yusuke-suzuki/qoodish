'use client';

import { Stack, TextField, Typography } from '@mui/material';
import { useParams, useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { memo, useState } from 'react';
import { recordPastJourney } from '../../actions/journeys.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import { isPastPeriod, toDatetimeLocal } from '../../utils/datetimeLocal.ts';
import AppDialog from '../common/AppDialog.tsx';

const DAY_MS = 24 * 60 * 60 * 1000;

type Props = {
  open: boolean;
  onClose: () => void;
  mapId: number;
};

export default memo(function PastJourneyDialog({
  open,
  onClose,
  mapId
}: Props) {
  const dictionary = useDictionary();
  const router = useRouter();
  const { lang } = useParams<{ lang: string }>();

  const [startedAt, setStartedAt] = useState('');
  const [finishedAt, setFinishedAt] = useState('');
  const [now, setNow] = useState('');
  const [loading, setLoading] = useState(false);

  const valid = isPastPeriod(startedAt, finishedAt, now);

  const handleEnter = () => {
    const current = new Date();
    const currentLocal = toDatetimeLocal(current);

    setNow(currentLocal);
    setFinishedAt(currentLocal);
    setStartedAt(toDatetimeLocal(new Date(current.getTime() - DAY_MS)));
  };

  const fail = (error?: string) => {
    setLoading(false);
    enqueueSnackbar(error ?? dictionary['an error occurred'], {
      variant: 'error'
    });
  };

  const handleConfirm = async () => {
    setLoading(true);

    try {
      const { success, data, error } = await recordPastJourney(
        mapId,
        new Date(startedAt).toISOString(),
        new Date(finishedAt).toISOString()
      );

      if (!success || !data) {
        fail(error);
        return;
      }

      router.push(`/${lang}/journeys/${data.id}`);
    } catch {
      fail();
    }
  };

  return (
    <AppDialog
      open={open}
      onClose={onClose}
      title={dictionary['record past journey']}
      maxWidth="xs"
      dividers
      disableClose={loading}
      onEnter={handleEnter}
      onExited={() => setLoading(false)}
      confirmAction={{
        label: dictionary['record past journey confirm'],
        loading,
        disabled: !valid,
        onClick: handleConfirm
      }}
    >
      <Stack spacing={3}>
        <Typography variant="body2" color="text.secondary">
          {dictionary['record past journey description']}
        </Typography>
        <TextField
          fullWidth
          type="datetime-local"
          label={dictionary['journey started at']}
          value={startedAt}
          error={Boolean(startedAt && finishedAt) && !valid}
          onChange={(event) => setStartedAt(event.target.value)}
          slotProps={{
            inputLabel: { shrink: true },
            htmlInput: { max: finishedAt || now }
          }}
        />
        <TextField
          fullWidth
          type="datetime-local"
          label={dictionary['journey finished at']}
          value={finishedAt}
          error={Boolean(startedAt && finishedAt) && !valid}
          onChange={(event) => setFinishedAt(event.target.value)}
          slotProps={{
            inputLabel: { shrink: true },
            htmlInput: { min: startedAt, max: now }
          }}
        />
      </Stack>
    </AppDialog>
  );
});
