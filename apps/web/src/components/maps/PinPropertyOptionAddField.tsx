'use client';

import { Add, Close } from '@mui/icons-material';
import {
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  TextField
} from '@mui/material';
import { type FormEvent, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';

const MAX_LENGTH = 30;

type Props = {
  value: string;
  disabled?: boolean;
  onChange: (value: string) => void;
  onAdd: (name: string) => void;
};

export default function PinPropertyOptionAddField({
  value,
  disabled,
  onChange,
  onAdd
}: Props) {
  const dictionary = useDictionary();

  const [open, setOpen] = useState(false);

  const trimmed = value.trim();
  const tooLong = trimmed.length > MAX_LENGTH;

  const add = () => {
    if (trimmed && !tooLong) {
      onAdd(trimmed);
    }
  };

  const discard = () => {
    onChange('');
    setOpen(false);
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    add();
  };

  const handleBlur = () => {
    if (tooLong) {
      return;
    }

    add();
    setOpen(false);
  };

  if (!open) {
    return (
      <ListItemButton
        disabled={disabled}
        onClick={() => setOpen(true)}
        sx={{ px: 0 }}
      >
        <ListItemIcon sx={{ pl: 1 }}>
          <Add />
        </ListItemIcon>
        <ListItemText primary={dictionary['add pin property option']} />
      </ListItemButton>
    );
  }

  return (
    <ListItem
      disableGutters
      secondaryAction={
        <IconButton
          edge="end"
          aria-label={dictionary.cancel}
          title={dictionary.cancel}
          onMouseDown={(event) => event.preventDefault()}
          onClick={discard}
        >
          <Close />
        </IconButton>
      }
      sx={{ pl: 7 }}
    >
      <form onSubmit={handleSubmit} style={{ flex: 1, minWidth: 0 }}>
        <TextField
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onBlur={handleBlur}
          onKeyDown={(event) => {
            if (event.key === 'Escape') {
              event.stopPropagation();
              discard();
            }
          }}
          placeholder={dictionary['pin property option name']}
          error={tooLong}
          helperText={tooLong && dictionary['max characters 30']}
          disabled={disabled}
          size="small"
          fullWidth
          autoFocus
          slotProps={{
            htmlInput: {
              'aria-label': dictionary['pin property option name'],
              enterKeyHint: 'enter'
            }
          }}
        />
      </form>
    </ListItem>
  );
}
