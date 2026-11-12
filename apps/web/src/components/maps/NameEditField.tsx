'use client';

import { TextField } from '@mui/material';
import { type FormEvent, type ReactNode, useRef, useState } from 'react';

type Props = {
  label: string;
  hideLabel?: boolean;
  defaultValue: string;
  maxLength: number;
  tooLongText: string;
  onSave: (name: string) => Promise<boolean>;
  startAdornment?: ReactNode;
};

export default function NameEditField({
  label,
  hideLabel,
  defaultValue,
  maxLength,
  tooLongText,
  onSave,
  startAdornment
}: Props) {
  const [name, setName] = useState(defaultValue);
  const [saving, setSaving] = useState(false);
  const savingRef = useRef(false);
  const cancelledRef = useRef(false);

  const trimmed = name.trim();
  const tooLong = trimmed.length > maxLength;

  const commit = async () => {
    if (savingRef.current || cancelledRef.current) {
      return;
    }

    if (!trimmed || trimmed === defaultValue) {
      setName(defaultValue);
      return;
    }

    if (tooLong) {
      return;
    }

    savingRef.current = true;
    setSaving(true);

    if (!(await onSave(trimmed).catch(() => false))) {
      setName(defaultValue);
    }

    savingRef.current = false;
    setSaving(false);
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    commit();
  };

  return (
    <form onSubmit={handleSubmit} style={{ flex: 1, minWidth: 0 }}>
      <TextField
        value={name}
        onChange={(event) => {
          cancelledRef.current = false;
          setName(event.target.value);
        }}
        onBlur={commit}
        onKeyDown={(event) => {
          if (event.key === 'Escape') {
            event.stopPropagation();
            cancelledRef.current = true;
            setName(defaultValue);
          }
        }}
        label={hideLabel ? undefined : label}
        error={tooLong}
        helperText={tooLong && tooLongText}
        disabled={saving}
        size="small"
        fullWidth
        slotProps={{
          input: { startAdornment },
          htmlInput: { 'aria-label': hideLabel ? label : undefined }
        }}
      />
    </form>
  );
}
