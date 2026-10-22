import { TextField } from '@mui/material';
import { type ChangeEvent, useEffect, useEffectEvent, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';

const MAX_LENGTH = 30;

type Props = {
  onChange: (name: string) => void;
  defaultValue?: string | null;
};

function PinNameForm({ onChange, defaultValue }: Props) {
  const dictionary = useDictionary();

  const [name, setName] = useState(defaultValue ?? '');
  const [error, setError] = useState<string | undefined>(
    name.length > MAX_LENGTH ? dictionary['max characters 30'] : undefined
  );

  const handleChange = (
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
      setError(dictionary['name is required']);
    }

    setName(input);
  };

  const notifyChange = useEffectEvent(onChange);

  useEffect(() => {
    notifyChange(name.length > MAX_LENGTH ? '' : name);
  }, [name]);

  return (
    <TextField
      label={dictionary.name}
      onChange={handleChange}
      error={!!error}
      helperText={error}
      fullWidth
      value={name}
      margin="normal"
      variant="outlined"
    />
  );
}

export default PinNameForm;
