'use client';

import { AddLocationAlt, CheckCircle, Place } from '@mui/icons-material';
import {
  Avatar,
  Box,
  Button,
  ButtonBase,
  Chip,
  Paper,
  Stack,
  Typography
} from '@mui/material';
import type { Pin } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalDateTime from '../../hooks/useLocalDateTime.ts';
import type { CheckinDraft, KeyedPhoto } from '../../utils/checkinDrafts.ts';

const THUMBNAIL_SIZE = 72;

const DATE_TIME_OPTIONS: Intl.DateTimeFormatOptions = {
  month: 'short',
  day: 'numeric',
  hour: '2-digit',
  minute: '2-digit'
};

const TIME_OPTIONS: Intl.DateTimeFormatOptions = {
  hour: '2-digit',
  minute: '2-digit'
};

export type PreviewPhoto = KeyedPhoto & {
  file: File;
  previewUrl: string;
};

type Props = {
  draft: CheckinDraft<PreviewPhoto>;
  pin: Pin | null;
  disabled: boolean;
  onTogglePhoto: (photoKey: string) => void;
  onChoosePin: () => void;
};

export default function CheckinDraftCard({
  draft,
  pin,
  disabled,
  onTogglePhoto,
  onChoosePin
}: Props) {
  const dictionary = useDictionary();
  const formatLocal = useLocalDateTime();

  const first = draft.photos[0];
  const last = draft.photos.at(-1) ?? first;
  const startedAt = new Date(first.capturedAt).toISOString();
  const finishedAt = new Date(last.capturedAt).toISOString();

  const sameDay =
    new Date(first.capturedAt).toDateString() ===
    new Date(last.capturedAt).toDateString();

  const timeRange =
    first.capturedAt === last.capturedAt
      ? formatLocal(startedAt, DATE_TIME_OPTIONS)
      : `${formatLocal(startedAt, DATE_TIME_OPTIONS)} – ${formatLocal(finishedAt, sameDay ? TIME_OPTIONS : DATE_TIME_OPTIONS)}`;

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Stack spacing={1.5}>
        <Typography variant="subtitle2">{timeRange}</Typography>

        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
          {draft.photos.map((photo) => {
            const selected = draft.selected.includes(photo.key);

            return (
              <ButtonBase
                key={photo.key}
                disabled={disabled}
                aria-pressed={selected}
                aria-label={photo.file.name}
                onClick={() => onTogglePhoto(photo.key)}
                sx={{ position: 'relative', borderRadius: 1 }}
              >
                <Avatar
                  variant="rounded"
                  src={photo.previewUrl}
                  alt={photo.file.name}
                  slotProps={{ img: { loading: 'lazy', decoding: 'async' } }}
                  sx={{
                    width: THUMBNAIL_SIZE,
                    height: THUMBNAIL_SIZE,
                    opacity: selected ? 1 : 0.4
                  }}
                />
                {selected && (
                  <CheckCircle
                    color="secondary"
                    fontSize="small"
                    sx={{
                      position: 'absolute',
                      top: 4,
                      right: 4,
                      bgcolor: 'background.paper',
                      borderRadius: '50%'
                    }}
                  />
                )}
              </ButtonBase>
            );
          })}
        </Box>

        {pin ? (
          <Box>
            <Chip
              icon={<Place />}
              label={pin.name}
              disabled={disabled}
              onClick={onChoosePin}
            />
          </Box>
        ) : (
          <Button
            variant="outlined"
            color="secondary"
            startIcon={<AddLocationAlt />}
            disabled={disabled}
            onClick={onChoosePin}
          >
            {dictionary['select pin']}
          </Button>
        )}
      </Stack>
    </Paper>
  );
}
