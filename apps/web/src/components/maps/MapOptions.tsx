import {
  FormControl,
  FormControlLabel,
  FormGroup,
  FormLabel,
  Switch
} from '@mui/material';
import { type ChangeEvent, useEffect, useEffectEvent, useState } from 'react';
import type { AppMap } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';

type MapOptions = {
  isPrivate: boolean;
};

type Props = {
  currentMap?: AppMap | null;
  onChange: (options: MapOptions) => void;
};

function MapOptions({ currentMap, onChange }: Props) {
  const dictionary = useDictionary();

  const [isPrivate, setIsPrivate] = useState(currentMap?.private ?? false);

  const notifyChange = useEffectEvent(onChange);

  useEffect(() => {
    notifyChange({ isPrivate });
  }, [isPrivate]);

  return (
    <FormControl component="fieldset" color="secondary" margin="normal">
      <FormLabel component="legend">{dictionary.options}</FormLabel>
      <FormGroup>
        <FormControlLabel
          control={
            <Switch
              color="secondary"
              checked={isPrivate}
              onChange={(
                _event: ChangeEvent<HTMLInputElement>,
                checked: boolean
              ) => setIsPrivate(checked)}
            />
          }
          label={dictionary['set this map to private']}
        />
      </FormGroup>
    </FormControl>
  );
}

export default MapOptions;
