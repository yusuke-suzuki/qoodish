'use client';

import { Close } from '@mui/icons-material';
import { Avatar, Box, IconButton } from '@mui/material';

export const THUMBNAIL_SIZE = 96;

type Props = {
  src: string;
  alt: string;
  removeLabel: string;
  disabled?: boolean;
  onRemove: () => void;
};

export default function RemovableThumbnail({
  src,
  alt,
  removeLabel,
  disabled,
  onRemove
}: Props) {
  return (
    <Box sx={{ position: 'relative' }}>
      <Avatar
        variant="rounded"
        src={src}
        alt={alt}
        slotProps={{ img: { loading: 'lazy', decoding: 'async' } }}
        sx={{ width: THUMBNAIL_SIZE, height: THUMBNAIL_SIZE }}
      />
      <IconButton
        size="small"
        aria-label={removeLabel}
        disabled={disabled}
        onClick={onRemove}
        sx={{
          position: 'absolute',
          top: -8,
          right: -8,
          p: 0.25,
          bgcolor: 'background.paper',
          boxShadow: 1,
          '&:hover': { bgcolor: 'background.paper' }
        }}
      >
        <Close sx={{ fontSize: 14 }} />
      </IconButton>
    </Box>
  );
}
