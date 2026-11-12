import { Stack } from '@mui/material';
import type { ReactNode } from 'react';
import type { PinProperty } from '../../../types/index.ts';
import { optionIcon } from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from './PinPropertyIcon.tsx';
import TagChip from './TagChip.tsx';

type Props = {
  optionIds: number[];
  pinProperties: PinProperty[];
  action?: ReactNode;
  disabled?: boolean;
  onDelete?: (property: PinProperty, optionId: number) => void;
};

export default function PinPropertyValues({
  optionIds,
  pinProperties,
  action,
  disabled,
  onDelete
}: Props) {
  const values = pinProperties.flatMap((property) =>
    property.options
      .filter((option) => optionIds.includes(option.id))
      .map((option) => ({ property, option }))
  );

  if (values.length < 1 && !action) {
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
          disabled={disabled}
          onDelete={onDelete && (() => onDelete(property, option.id))}
        />
      ))}
      {action}
    </Stack>
  );
}
