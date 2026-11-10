import { Box, Button, Stack, Typography } from '@mui/material';
import { useId, useState } from 'react';
import type {
  AppMap,
  PinProperty,
  PinPropertyOption
} from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import { chooseOptions, optionIcon } from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';
import TagChip from '../common/TagChip.tsx';
import PinPropertiesDialog from '../maps/PinPropertiesDialog.tsx';

type FieldProps = {
  property: PinProperty;
  value: number[];
  disabled?: boolean;
  onChange: (optionIds: number[]) => void;
};

function PinPropertyField({ property, value, disabled, onChange }: FieldProps) {
  const chosenIds = property.options
    .map((option) => option.id)
    .filter((id) => value.includes(id));

  const handleToggle = (option: PinPropertyOption) => {
    if (chosenIds.includes(option.id)) {
      onChange(
        chooseOptions(
          value,
          property,
          chosenIds.filter((id) => id !== option.id)
        )
      );
    } else if (property.multiple) {
      onChange(chooseOptions(value, property, [...chosenIds, option.id]));
    } else {
      onChange(chooseOptions(value, property, [option.id]));
    }
  };

  return (
    <Stack
      role="group"
      aria-label={property.name}
      direction="row"
      spacing={1}
      useFlexGap
      flexWrap="wrap"
    >
      {property.options.map((option) => {
        const chosen = chosenIds.includes(option.id);

        return (
          <TagChip
            key={option.id}
            label={option.name}
            title={property.name}
            icon={<PinPropertyIcon icon={optionIcon(property, option)} />}
            tagColor={property.color}
            color={chosen ? 'secondary' : 'default'}
            variant={chosen ? 'filled' : 'outlined'}
            aria-pressed={chosen}
            disabled={disabled}
            onClick={() => handleToggle(option)}
            sx={{
              height: 'auto',
              '& .MuiChip-label': {
                display: 'block',
                whiteSpace: 'normal',
                overflowWrap: 'anywhere'
              }
            }}
          />
        );
      })}
    </Stack>
  );
}

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

  const [managing, setManaging] = useState(false);

  const offeredProperties = pinProperties.filter(
    (property) => property.options.length > 0
  );

  if (!map?.editable && offeredProperties.length < 1) {
    return null;
  }

  return (
    <Box component="section" aria-labelledby={headingId} sx={{ mt: 2 }}>
      <Stack direction="row" alignItems="center" spacing={1}>
        <Typography
          id={headingId}
          variant="subtitle1"
          component="h3"
          sx={{ flex: 1, minWidth: 0 }}
        >
          {dictionary['pin property fields']}
        </Typography>
        {map?.editable && (
          <Button
            size="small"
            color="secondary"
            onClick={() => setManaging(true)}
            disabled={disabled}
          >
            {dictionary['pin properties']}
          </Button>
        )}
      </Stack>

      <Stack spacing={2} sx={{ mt: 1 }}>
        {offeredProperties.map((property) => (
          <PinPropertyField
            key={property.id}
            property={property}
            value={value}
            disabled={disabled}
            onChange={onChange}
          />
        ))}
      </Stack>

      {map?.editable && (
        <PinPropertiesDialog
          open={managing}
          onClose={() => setManaging(false)}
          map={map}
          pinProperties={pinProperties}
        />
      )}
    </Box>
  );
}
