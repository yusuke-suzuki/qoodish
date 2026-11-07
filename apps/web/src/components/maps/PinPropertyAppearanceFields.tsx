import {
  Checkbox,
  FormControlLabel,
  Stack,
  TextField,
  Typography
} from '@mui/material';
import useDictionary from '../../hooks/useDictionary.ts';
import { isSingleGrapheme } from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';
import TagChip from '../common/TagChip.tsx';

const DEFAULT_COLOR = '#1e88e5';

export type PinPropertyAppearance = {
  icon: string | null;
  color: string | null;
};

export function appearanceInvalid({ icon }: PinPropertyAppearance): boolean {
  return icon !== null && !isSingleGrapheme(icon);
}

type Props = {
  name: string;
  value: PinPropertyAppearance;
  disabled?: boolean;
  onChange: (value: PinPropertyAppearance) => void;
};

export default function PinPropertyAppearanceFields({
  name,
  value,
  disabled,
  onChange
}: Props) {
  const dictionary = useDictionary();

  const invalid = appearanceInvalid(value);

  return (
    <>
      <TextField
        label={dictionary['pin property icon']}
        value={value.icon ?? ''}
        onChange={(event) => {
          const icon = event.target.value.trim();

          onChange({ ...value, icon: icon === '' ? null : icon });
        }}
        error={invalid}
        helperText={dictionary['pin property icon helper']}
        disabled={disabled}
        fullWidth
        margin="normal"
      />
      <Stack
        direction="row"
        alignItems="center"
        spacing={2}
        useFlexGap
        flexWrap="wrap"
        sx={{ mt: 2, mb: 1 }}
      >
        <TextField
          type="color"
          label={dictionary['pin property color']}
          value={value.color ?? DEFAULT_COLOR}
          onChange={(event) =>
            onChange({ ...value, color: event.target.value })
          }
          disabled={disabled || value.color === null}
          sx={{ width: 96 }}
        />
        <FormControlLabel
          control={
            <Checkbox
              checked={value.color === null}
              onChange={(event) =>
                onChange({
                  ...value,
                  color: event.target.checked ? null : DEFAULT_COLOR
                })
              }
              disabled={disabled}
            />
          }
          label={dictionary['no color']}
        />
      </Stack>
      <Stack direction="row" alignItems="center" spacing={1} sx={{ mt: 1 }}>
        <Typography variant="body2" color="text.secondary">
          {dictionary.preview}
        </Typography>
        <TagChip
          icon={<PinPropertyIcon icon={invalid ? null : value.icon} />}
          label={name || dictionary['pin property name']}
          tagColor={value.color}
          size="small"
        />
      </Stack>
    </>
  );
}
