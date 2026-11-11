'use client';

import { Add, Close } from '@mui/icons-material';
import {
  Button,
  IconButton,
  ListItem,
  ListItemIcon,
  TextField
} from '@mui/material';
import { type FocusEvent, type FormEvent, useRef, useState } from 'react';
import { flushSync } from 'react-dom';
import useDictionary from '../../hooks/useDictionary.ts';
import PinPropertyIconCell from './PinPropertyIconCell.tsx';

const MAX_LENGTH = 30;

type Props = {
  value: string;
  icon: string | null;
  disabled?: boolean;
  onChange: (value: string) => void;
  onAdd: (name: string) => void;
};

export default function PinPropertyOptionAddField({
  value,
  icon,
  disabled,
  onChange,
  onAdd
}: Props) {
  const dictionary = useDictionary();
  const inputRef = useRef<HTMLInputElement>(null);
  const cancelRef = useRef<HTMLButtonElement>(null);
  const addButtonRef = useRef<HTMLButtonElement>(null);
  const discardingRef = useRef(false);

  const [open, setOpen] = useState(false);

  const shown = open || value !== '';
  const trimmed = value.trim();
  const tooLong = trimmed.length > MAX_LENGTH;

  const add = () => {
    if (trimmed && !tooLong) {
      onAdd(trimmed);
    }
  };

  const discard = () => {
    discardingRef.current = true;
    onChange('');
    setOpen(false);
    addButtonRef.current?.focus();
    discardingRef.current = false;
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    add();
  };

  const handleBlur = (event: FocusEvent<HTMLElement>) => {
    if (
      discardingRef.current ||
      event.relatedTarget === inputRef.current ||
      event.relatedTarget === cancelRef.current ||
      tooLong
    ) {
      return;
    }

    add();
    setOpen(false);
  };

  const handleOpen = () => {
    flushSync(() => setOpen(true));
    inputRef.current?.focus();
  };

  return (
    <>
      {shown && (
        <ListItem
          disableGutters
          secondaryAction={
            <IconButton
              ref={cancelRef}
              edge="end"
              aria-label={dictionary.cancel}
              title={dictionary.cancel}
              onMouseDown={(event) => event.preventDefault()}
              onBlur={handleBlur}
              onClick={discard}
            >
              <Close />
            </IconButton>
          }
        >
          <ListItemIcon>
            <PinPropertyIconCell icon={icon} />
          </ListItemIcon>
          <form onSubmit={handleSubmit} style={{ flex: 1, minWidth: 0 }}>
            <TextField
              inputRef={inputRef}
              value={value}
              onChange={(event) => onChange(event.target.value)}
              onBlur={handleBlur}
              onKeyDown={(event) => {
                if (event.key === 'Escape' && !event.nativeEvent.isComposing) {
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
              slotProps={{
                htmlInput: {
                  'aria-label': dictionary['pin property option name'],
                  enterKeyHint: 'enter'
                }
              }}
            />
          </form>
        </ListItem>
      )}
      <ListItem disableGutters>
        <Button
          ref={addButtonRef}
          startIcon={<Add />}
          disabled={disabled}
          onClick={handleOpen}
        >
          {dictionary['add pin property option']}
        </Button>
      </ListItem>
    </>
  );
}
