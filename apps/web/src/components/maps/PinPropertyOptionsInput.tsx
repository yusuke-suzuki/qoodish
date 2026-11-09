'use client';

import { Autocomplete, Chip, TextField } from '@mui/material';
import { useState } from 'react';
import type { PinPropertyOption } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';

const MAX_LENGTH = 30;

type Props = {
  options: PinPropertyOption[];
  onCreate: (name: string) => Promise<boolean>;
  onRename: (option: PinPropertyOption) => void;
  onDelete: (option: PinPropertyOption) => void;
};

export default function PinPropertyOptionsInput({
  options,
  onCreate,
  onRename,
  onDelete
}: Props) {
  const dictionary = useDictionary();

  const [input, setInput] = useState('');
  const [pendingNames, setPendingNames] = useState<string[]>([]);
  const [shownOptions, setShownOptions] = useState(options);

  if (options !== shownOptions) {
    setShownOptions(options);
    setPendingNames((names) =>
      names.filter((name) => !options.some((option) => option.name === name))
    );
  }

  const trimmed = input.trim();
  const tooLong = trimmed.length > MAX_LENGTH;

  const create = async (name: string) => {
    const newName = name.trim();

    if (!newName || newName.length > MAX_LENGTH) {
      return;
    }

    setInput('');

    if (
      options.some((option) => option.name === newName) ||
      pendingNames.includes(newName)
    ) {
      return;
    }

    setPendingNames((names) => [...names, newName]);

    const created = await onCreate(newName).catch(() => false);

    if (!created) {
      setPendingNames((names) =>
        names.filter((pending) => pending !== newName)
      );
      setInput((current) => current || newName);
    }
  };

  return (
    <Autocomplete<PinPropertyOption | string, true, true, true>
      multiple
      freeSolo
      disableClearable
      options={[]}
      value={[...options, ...pendingNames]}
      getOptionLabel={(option) =>
        typeof option === 'string' ? option : option.name
      }
      inputValue={input}
      onInputChange={(_event, value, reason) => {
        if (reason !== 'reset') {
          setInput(value);
        }
      }}
      onChange={(_event, _value, reason, details) => {
        const option = details?.option;

        if (reason === 'createOption' && typeof option === 'string') {
          create(option);
        }

        if (reason === 'removeOption' && option && typeof option !== 'string') {
          onDelete(option);
        }
      }}
      renderValue={(value, getItemProps) =>
        value.map((option, index) => {
          const { key, ...itemProps } = getItemProps({ index });

          return typeof option === 'string' ? (
            <Chip
              key={key}
              {...itemProps}
              label={option}
              onDelete={undefined}
              disabled
            />
          ) : (
            <Chip
              key={key}
              {...itemProps}
              label={option.name}
              onClick={() => onRename(option)}
            />
          );
        })
      }
      renderInput={(params) => (
        <TextField
          {...params}
          label={dictionary['pin property options']}
          error={tooLong}
          helperText={
            tooLong
              ? dictionary['max characters 30']
              : dictionary['add options with enter']
          }
          size="small"
        />
      )}
    />
  );
}
