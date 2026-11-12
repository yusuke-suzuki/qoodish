import { Stack } from '@mui/material';
import type { Pin, PinProperty } from '../../../types/index.ts';
import { optionIcon } from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from './PinPropertyIcon.tsx';
import TagChip from './TagChip.tsx';

type Props = {
  pin: Pin;
  pinProperties: PinProperty[];
};

export default function PinPropertyValues({ pin, pinProperties }: Props) {
  const values = pinProperties.flatMap((property) =>
    property.options
      .filter((option) => pin.property_option_ids.includes(option.id))
      .map((option) => ({ property, option }))
  );

  if (values.length < 1) {
    return null;
  }

  return (
    <Stack
      direction="row"
      spacing={1}
      useFlexGap
      flexWrap="wrap"
      sx={{ my: 1 }}
    >
      {values.map(({ property, option }) => (
        <TagChip
          key={option.id}
          icon={<PinPropertyIcon icon={optionIcon(property, option)} />}
          label={option.name}
          title={property.name}
          tagColor={property.color}
        />
      ))}
    </Stack>
  );
}
