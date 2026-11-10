'use client';

import {
  Autocomplete,
  Box,
  InputAdornment,
  Stack,
  TextField,
  ToggleButton,
  ToggleButtonGroup
} from '@mui/material';
import { useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { type FormEvent, useState, useTransition } from 'react';
import { createPinProperty } from '../../actions/pinProperties.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import type { PinPropertyAppearance } from '../../utils/pinPropertyOptions.ts';
import AppDialog from '../common/AppDialog.tsx';
import PinPropertyColorPicker from './PinPropertyColorPicker.tsx';
import PinPropertyIconPicker from './PinPropertyIconPicker.tsx';
import PinPropertyTypeIcon from './PinPropertyTypeIcon.tsx';

const MAX_LENGTH = 30;

const NO_APPEARANCE: PinPropertyAppearance = { icon: null, color: null };

type Props = {
  open: boolean;
  onClose: () => void;
  mapId: number;
};

function uniqueNames(names: string[]): string[] {
  return Array.from(
    new Set(names.map((name) => name.trim()).filter((name) => name))
  );
}

export default function NewPinPropertyDialog({ open, onClose, mapId }: Props) {
  const dictionary = useDictionary();
  const router = useRouter();

  const [name, setName] = useState('');
  const [multiple, setMultiple] = useState(false);
  const [appearance, setAppearance] =
    useState<PinPropertyAppearance>(NO_APPEARANCE);
  const [options, setOptions] = useState<string[]>([]);
  const [optionInput, setOptionInput] = useState('');
  const [isPending, startTransition] = useTransition();

  const trimmed = name.trim();
  const tooLong = trimmed.length > MAX_LENGTH;
  const submittedOptions = uniqueNames([...options, optionInput]);
  const optionTooLong = submittedOptions.some(
    (option) => option.length > MAX_LENGTH
  );

  const typeLabel = multiple
    ? dictionary['multi select']
    : dictionary['single select'];

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    startTransition(async () => {
      const result = await createPinProperty(mapId, {
        name: trimmed,
        multiple,
        ...appearance,
        options: submittedOptions
      });

      if (result.success) {
        router.refresh();
        onClose();
      }

      if (result.error || !result.success) {
        enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
          variant: 'error'
        });
      }
    });
  };

  const handleExited = () => {
    setName('');
    setMultiple(false);
    setAppearance(NO_APPEARANCE);
    setOptions([]);
    setOptionInput('');
  };

  return (
    <AppDialog
      open={open}
      onClose={onClose}
      title={dictionary['add pin property']}
      fullScreenOnMobile
      cancelLabel={dictionary.cancel}
      disableClose={isPending}
      disableQuickDismiss
      onSubmit={handleSubmit}
      onExited={handleExited}
      confirmAction={{
        label: dictionary.add,
        type: 'submit',
        disabled: !trimmed || tooLong || optionTooLong,
        loading: isPending
      }}
    >
      <Stack direction="row" alignItems="center" sx={{ mt: 1 }}>
        <Box sx={{ minWidth: 56 }}>
          <PinPropertyIconPicker
            icon={appearance.icon}
            disabled={isPending}
            onChange={(icon) => setAppearance({ ...appearance, icon })}
          />
        </Box>
        <TextField
          label={dictionary['pin property name']}
          value={name}
          onChange={(event) => setName(event.target.value)}
          error={tooLong}
          helperText={tooLong && dictionary['max characters 30']}
          disabled={isPending}
          size="small"
          fullWidth
          autoFocus
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <Box
                    component="span"
                    role="img"
                    aria-label={typeLabel}
                    sx={{ display: 'flex' }}
                  >
                    <PinPropertyTypeIcon multiple={multiple} fontSize="small" />
                  </Box>
                </InputAdornment>
              )
            }
          }}
        />
        <Box sx={{ ml: 1 }}>
          <PinPropertyColorPicker
            color={appearance.color}
            disabled={isPending}
            onChange={(color) => setAppearance({ ...appearance, color })}
          />
        </Box>
      </Stack>
      <Box sx={{ pl: 7 }}>
        <ToggleButtonGroup
          exclusive
          fullWidth
          size="small"
          color="secondary"
          aria-label={dictionary['pin property type']}
          value={multiple}
          onChange={(_event, value: boolean | null) => {
            if (value !== null) {
              setMultiple(value);
            }
          }}
          disabled={isPending}
          sx={{ mt: 2 }}
        >
          <ToggleButton value={false}>
            <Stack direction="row" alignItems="center" spacing={1}>
              <PinPropertyTypeIcon multiple={false} fontSize="small" />
              <span>{dictionary['single select']}</span>
            </Stack>
          </ToggleButton>
          <ToggleButton value={true}>
            <Stack direction="row" alignItems="center" spacing={1}>
              <PinPropertyTypeIcon multiple fontSize="small" />
              <span>{dictionary['multi select']}</span>
            </Stack>
          </ToggleButton>
        </ToggleButtonGroup>
        <Autocomplete
          multiple
          freeSolo
          options={[]}
          value={options}
          onChange={(_event, value) => setOptions(uniqueNames(value))}
          inputValue={optionInput}
          onInputChange={(_event, value) => setOptionInput(value)}
          disabled={isPending}
          sx={{ mt: 2 }}
          renderInput={(params) => (
            <TextField
              {...params}
              label={dictionary['pin property options']}
              error={optionTooLong}
              helperText={
                optionTooLong
                  ? dictionary['max characters 30']
                  : dictionary['add options with enter']
              }
              size="small"
            />
          )}
        />
      </Box>
    </AppDialog>
  );
}
