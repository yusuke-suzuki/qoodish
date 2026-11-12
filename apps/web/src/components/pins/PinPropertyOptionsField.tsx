import { Box, Typography } from '@mui/material';
import { useId } from 'react';
import type { AppMap, PinProperty } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import { toggleOption } from '../../utils/pinPropertyOptions.ts';
import PinTagEditor from './PinTagEditor.tsx';

type Props = {
  map: AppMap | null;
  pinProperties: PinProperty[];
  value: number[];
  disabled?: boolean;
  onChange: (optionIds: number[]) => void;
};

export default function PinPropertyOptionsField({
  map,
  pinProperties,
  value,
  disabled,
  onChange
}: Props) {
  const dictionary = useDictionary();
  const headingId = useId();

  const offered = pinProperties.some((property) => property.options.length > 0);

  if (!map?.editable && !offered) {
    return null;
  }

  return (
    <Box component="section" aria-labelledby={headingId} sx={{ mt: 2 }}>
      <Typography id={headingId} variant="subtitle1" component="h3">
        {dictionary['pin property fields']}
      </Typography>
      <PinTagEditor
        map={map}
        pinProperties={pinProperties}
        value={value}
        disabled={disabled}
        onToggle={(property, optionId) =>
          onChange(toggleOption(value, property, optionId))
        }
      />
    </Box>
  );
}
