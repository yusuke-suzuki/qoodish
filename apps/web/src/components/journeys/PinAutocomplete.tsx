import { Check, HistoryEdu } from '@mui/icons-material';
import {
  Autocomplete,
  Avatar,
  ListItem,
  ListItemAvatar,
  ListItemIcon,
  ListItemText,
  TextField
} from '@mui/material';
import type { Pin } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';

type Props = {
  pins: Pin[];
  value: Pin | null;
  /** Pins other check-ins already use, marked in the options. */
  usedPinIds: Set<number | null>;
  disabled: boolean;
  onSelect: (pin: Pin) => void;
};

export default function PinAutocomplete({
  pins,
  value,
  usedPinIds,
  disabled,
  onSelect
}: Props) {
  const dictionary = useDictionary();

  return (
    <Autocomplete
      fullWidth
      size="small"
      disableClearable={value !== null}
      disabled={disabled}
      options={pins}
      noOptionsText={dictionary['pin not found']}
      value={value}
      onChange={(_, pin) => {
        if (pin) {
          onSelect(pin);
        }
      }}
      getOptionKey={(pin) => pin.id}
      getOptionLabel={(pin) => pin.name}
      isOptionEqualToValue={(option, selected) => option.id === selected.id}
      renderOption={({ key, ...optionProps }, pin) => (
        <ListItem key={key} {...optionProps}>
          <ListItemAvatar>
            {pin.images.length > 0 ? (
              <Avatar
                alt={pin.name}
                variant="rounded"
                src={pin.images[0].avatar}
              />
            ) : (
              <Avatar alt={pin.name} variant="rounded">
                <HistoryEdu />
              </Avatar>
            )}
          </ListItemAvatar>
          <ListItemText
            primary={pin.name}
            secondary={pin.comment}
            slotProps={{
              primary: { noWrap: true },
              secondary: { noWrap: true }
            }}
          />
          {usedPinIds.has(pin.id) && (
            <ListItemIcon sx={{ minWidth: 'auto' }}>
              <Check color="disabled" fontSize="small" />
            </ListItemIcon>
          )}
        </ListItem>
      )}
      renderInput={(params) => (
        <TextField
          {...params}
          variant="standard"
          label={dictionary['select pin']}
        />
      )}
    />
  );
}
