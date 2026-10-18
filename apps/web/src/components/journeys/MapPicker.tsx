import { Map as MapIcon } from '@mui/icons-material';
import {
  Avatar,
  List,
  ListItemAvatar,
  ListItemButton,
  ListItemText,
  Paper
} from '@mui/material';
import type { CountedMap } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import DiscoverButton from '../common/DiscoverButton.tsx';
import NoContents from '../common/NoContents.tsx';

type Props = {
  maps: CountedMap[];
  selectedId: number | null;
  onSelect: (map: CountedMap) => void;
};

export default function MapPicker({ maps, selectedId, onSelect }: Props) {
  const dictionary = useDictionary();

  if (maps.length < 1) {
    return (
      <NoContents
        icon={MapIcon}
        message={dictionary['maps will see here']}
        action={<DiscoverButton />}
      />
    );
  }

  return (
    <Paper variant="outlined">
      <List disablePadding>
        {maps.map((map, index) => (
          <ListItemButton
            key={map.id}
            selected={map.id === selectedId}
            disabled={map.pins_count < 1}
            onClick={() => onSelect(map)}
            divider={index < maps.length - 1}
          >
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
          </ListItemButton>
        ))}
      </List>
    </Paper>
  );
}
