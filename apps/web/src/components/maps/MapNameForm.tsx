import { TextField } from '@mui/material';
import { type ChangeEvent, useEffect, useEffectEvent, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';

const MAX_LENGTH = 30;

type Props = {
  onChange: (name: string) => void;
  defaultValue?: string | null;
};

export default function MapNameForm({ onChange, defaultValue }: Props) {
  const dictionary = useDictionary();

  const [name, setName] = useState(defaultValue ?? '');
  const [error, setError] = useState<string | undefined>(undefined);

  const handleNameChange = (
    e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const input = e.target.value;

    if (input) {
      if (input.length > MAX_LENGTH) {
        setError(dictionary['max characters 30']);
      } else {
        setError(undefined);
      }
    } else {
      setError(dictionary['map name is required']);
    }

    setName(input);
  };

  const notifyChange = useEffectEvent(onChange);

  useEffect(() => {
    notifyChange(name);
  }, [name]);

  return (
    <TextField
      label={dictionary['map name']}
      onChange={handleNameChange}
      error={!!error}
      helperText={error}
      fullWidth
      value={name}
      margin="normal"
      variant="outlined"
    />
  );
}
