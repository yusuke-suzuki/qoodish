'use client';

import { Delete, Place } from '@mui/icons-material';
import {
  TimelineConnector,
  TimelineContent,
  TimelineDot,
  TimelineItem,
  TimelineSeparator
} from '@mui/lab';
import { Box, IconButton, Typography } from '@mui/material';
import type { Pin } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalDateTime from '../../hooks/useLocalDateTime.ts';
import type { CheckinDraft, KeyedPhoto } from '../../utils/checkinDrafts.ts';
import PinAutocomplete from './PinAutocomplete.tsx';
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
  pin: Pin | null;
  pins: Pin[];
  usedPinIds: Set<number | null>;
  disabled: boolean;
  isLast: boolean;
  onRemovePhoto: (photoKey: string) => void;
  onRemove: () => void;
  onSelectPin: (pin: Pin) => void;
};

export default function CheckinDraftItem({
  draft,
  pin,
  pins,
  usedPinIds,
  disabled,
  isLast,
  onRemovePhoto,
  onRemove,
  onSelectPin
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

  // Laid out like a check-in on the journey page, so the draft reads as the
  // check-in it is about to become.
  return (
    <TimelineItem>
      <TimelineSeparator>
        <TimelineDot
          color={pin ? 'primary' : 'grey'}
          variant={pin ? 'filled' : 'outlined'}
        >
          <Place fontSize="small" />
        </TimelineDot>
        {!isLast && <TimelineConnector />}
      </TimelineSeparator>
      <TimelineContent sx={{ py: '12px', px: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1 }}>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <PinAutocomplete
              pins={pins}
              value={pin}
              usedPinIds={usedPinIds}
              disabled={disabled}
              onSelect={onSelectPin}
            />

            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ display: 'block', mt: 0.5 }}
            >
              {timeRange}
            </Typography>
          </Box>

          <IconButton
            size="small"
            disabled={disabled}
            aria-label={dictionary['exclude checkin']}
            onClick={onRemove}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Box>

        {selectedPhotos.length > 0 && (
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5, mt: 1 }}>
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
      </TimelineContent>
    </TimelineItem>
  );
}
