'use client';

import { Add } from '@mui/icons-material';
import { ListItem, ListItemIcon, TextField } from '@mui/material';
import type { FormEvent } from 'react';
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

  const trimmed = value.trim();
  const tooLong = trimmed.length > MAX_LENGTH;

  const add = () => {
    if (trimmed && !tooLong) {
      onAdd(trimmed);
    }
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    add();
  };

  return (
    <ListItem disableGutters>
      <ListItemIcon>
        <Add />
      </ListItemIcon>
      <form onSubmit={handleSubmit} style={{ flex: 1, minWidth: 0 }}>
        <TextField
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onBlur={add}
          placeholder={dictionary['add pin property option']}
          error={tooLong}
          helperText={tooLong && dictionary['max characters 30']}
          disabled={disabled}
          size="small"
          fullWidth
          slotProps={{
            htmlInput: {
              'aria-label': dictionary['add pin property option'],
              enterKeyHint: 'enter'
            }
          }}
        />
      </form>
    </ListItem>
  );
}
