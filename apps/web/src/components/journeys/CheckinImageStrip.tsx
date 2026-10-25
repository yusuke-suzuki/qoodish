'use client';

import { AddPhotoAlternate } from '@mui/icons-material';
import {
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogTitle,
  IconButton
} from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import { type ChangeEvent, useId, useState } from 'react';
import type { Image, JourneyCheckin } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import uploadImage, {
  splitOversizedImages,
  uploadFailureMessage
} from '../../utils/uploadImage.ts';
import RemovableThumbnail, { THUMBNAIL_SIZE } from './RemovableThumbnail.tsx';

type Props = {
  checkin: JourneyCheckin;
  onAttach: (checkin: JourneyCheckin, image: Image) => Promise<void>;
  onRemove: (checkin: JourneyCheckin, imageId: number) => Promise<boolean>;
};

function CheckinImageStrip({ checkin, onAttach, onRemove }: Props) {
  const dictionary = useDictionary();

  const inputId = useId();
  const [uploading, setUploading] = useState(false);
  const [pendingDelete, setPendingDelete] = useState<number | null>(null);
  const [deleting, setDeleting] = useState(false);

  const handleFilesChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const { accepted, oversized } = splitOversizedImages(
      Array.from(event.target.files ?? [])
    );
    event.target.value = '';

    if (oversized.length > 0) {
      enqueueSnackbar(dictionary['image too large'], { variant: 'error' });
    }

    if (accepted.length < 1) {
      return;
    }

    setUploading(true);

    try {
      for (const file of accepted) {
        const image = await uploadImage(file);
        await onAttach(checkin, image);
      }
    } catch (error) {
      enqueueSnackbar(uploadFailureMessage(error, dictionary), {
        variant: 'error'
      });
    } finally {
      setUploading(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (pendingDelete === null) {
      return;
    }

    setDeleting(true);
    const success = await onRemove(checkin, pendingDelete);
    setDeleting(false);
    setPendingDelete(null);

    if (success) {
      enqueueSnackbar(dictionary['delete image success'], {
        variant: 'success'
      });
    }
  };

  return (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5 }}>
      {checkin.images.map((image) => (
        <RemovableThumbnail
          key={image.id}
          src={image.card}
          alt={checkin.spot.name}
          removeLabel={dictionary.delete}
          onRemove={() => setPendingDelete(image.id)}
        />
      ))}

      <input
        accept="image/*"
        multiple
        style={{ display: 'none' }}
        id={inputId}
        type="file"
        onChange={handleFilesChange}
      />
      <label htmlFor={inputId}>
        <IconButton
          component="span"
          aria-label={dictionary['add images']}
          disabled={uploading}
          sx={{
            width: THUMBNAIL_SIZE,
            height: THUMBNAIL_SIZE,
            borderRadius: 1,
            border: '1px dashed',
            borderColor: 'divider'
          }}
        >
          {uploading ? (
            <CircularProgress size={20} color="inherit" />
          ) : (
            <AddPhotoAlternate fontSize="small" />
          )}
        </IconButton>
      </label>

      <Dialog
        open={pendingDelete !== null}
        onClose={() => setPendingDelete(null)}
        maxWidth="xs"
      >
        <DialogTitle>{dictionary['sure to delete image']}</DialogTitle>
        <DialogActions>
          <Button color="inherit" onClick={() => setPendingDelete(null)}>
            {dictionary.cancel}
          </Button>
          <Button
            color="error"
            variant="contained"
            loading={deleting}
            onClick={handleConfirmDelete}
          >
            {dictionary.delete}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default CheckinImageStrip;
