'use client';

import { AddLocationAlt, Delete, Place } from '@mui/icons-material';
import {
  Box,
  Button,
  Chip,
  IconButton,
  Paper,
  Stack,
  Typography
} from '@mui/material';
import type { Pin } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalDateTime from '../../hooks/useLocalDateTime.ts';
import type { CheckinDraft, KeyedPhoto } from '../../utils/checkinDrafts.ts';
import RemovableThumbnail from './RemovableThumbnail.tsx';

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
  pin?: Pin | null;
  disabled: boolean;
  onRemovePhoto: (photoKey: string) => void;
  onRemove: () => void;
  /** Without it the card is a preview and offers no pin. */
  onChoosePin?: () => void;
};

export default function CheckinDraftCard({
  draft,
  pin,
  disabled,
  onRemovePhoto,
  onRemove,
  onChoosePin
}: Props) {
  const dictionary = useDictionary();
  const formatLocal = useLocalDateTime();

  // Photos past the check-in limit stay out of view, as they will not be
  // attached; they still date the check-in.
  const selectedPhotos = draft.photos.filter((photo) =>
    draft.selected.includes(photo.key)
  );
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
        <Stack
          direction="row"
          spacing={1}
          sx={{ alignItems: 'center', justifyContent: 'space-between' }}
        >
          <Typography variant="subtitle2">{timeRange}</Typography>
          <IconButton
            size="small"
            disabled={disabled}
            aria-label={dictionary['exclude checkin']}
            onClick={onRemove}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Stack>

        {selectedPhotos.length > 0 && (
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5 }}>
            {selectedPhotos.map((photo) => (
              <RemovableThumbnail
                key={photo.key}
                src={photo.previewUrl}
                alt={photo.file.name}
                removeLabel={dictionary['exclude photo']}
                disabled={disabled}
                onRemove={() => onRemovePhoto(photo.key)}
              />
            ))}
          </Box>
        )}

        {!onChoosePin ? null : pin ? (
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
