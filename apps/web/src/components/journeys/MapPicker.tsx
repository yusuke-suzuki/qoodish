import { Map as MapIcon } from '@mui/icons-material';
import {
  Autocomplete,
  Avatar,
  ListItem,
  ListItemAvatar,
  ListItemText,
  TextField
} from '@mui/material';
import type { CountedMap } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import DiscoverButton from '../common/DiscoverButton.tsx';
import NoContents from '../common/NoContents.tsx';

type Props = {
  /** null while the maps are still loading. */
  maps: CountedMap[] | null;
  selected: CountedMap | null;
  onSelect: (map: CountedMap) => void;
};

export default function MapPicker({ maps, selected, onSelect }: Props) {
  const dictionary = useDictionary();

  if (maps !== null && maps.length < 1) {
    return (
      <NoContents
        icon={MapIcon}
        message={dictionary['maps will see here']}
        action={<DiscoverButton />}
      />
    );
  }

  // A single field keeps the step's Next button in view however many maps
  // there are, and typing narrows them down.
  return (
    <Autocomplete
      fullWidth
      disableClearable={selected !== null}
      options={maps ?? []}
      loading={maps === null}
      loadingText={dictionary.loading}
      noOptionsText={dictionary['map not found']}
      value={selected}
      onChange={(_, map) => {
        if (map) {
          onSelect(map);
        }
      }}
      getOptionKey={(map) => map.id}
      getOptionLabel={(map) => map.name}
      getOptionDisabled={(map) => map.pins_count < 1}
      isOptionEqualToValue={(option, value) => option.id === value.id}
      renderOption={({ key, ...optionProps }, map) => (
        <ListItem key={key} {...optionProps}>
          <ListItemAvatar>
            <Avatar variant="rounded" alt={map.name} src={map.image?.avatar}>
              <MapIcon />
            </Avatar>
          </ListItemAvatar>
          <ListItemText
            primary={map.name}
            secondary={
              map.pins_count < 1 ? dictionary['no pins yet'] : map.author.name
            }
            slotProps={{
              primary: { noWrap: true },
              secondary: { noWrap: true }
            }}
          />
        </ListItem>
      )}
      renderInput={(params) => <TextField {...params} label={dictionary.map} />}
    />
  );
}
