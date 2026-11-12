'use client';

import { Add, Check, Sell } from '@mui/icons-material';
import {
  Chip,
  Divider,
  ListItemIcon,
  ListItemText,
  ListSubheader,
  Menu,
  MenuItem
} from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import { useId, useState } from 'react';
import type { AppMap, Pin, PinProperty } from '../../../types/index.ts';
import { updatePinPropertyOptions } from '../../actions/pins.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import {
  offeredOptionIds,
  optionIcon,
  toggleOption
} from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';
import PinPropertyValues from '../common/PinPropertyValues.tsx';
import PinPropertiesDialog from '../maps/PinPropertiesDialog.tsx';

type StoredTags = { ids: number[]; updatedAt: string };

function storedTags(
  pin: Pick<Pin, 'property_option_ids' | 'updated_at'>
): StoredTags {
  return { ids: pin.property_option_ids, updatedAt: pin.updated_at };
}

function newer(known: StoredTags, incoming: StoredTags): StoredTags {
  return incoming.updatedAt >= known.updatedAt ? incoming : known;
}

type Props = {
  pin: Pin;
  map: AppMap | null;
  pinProperties: PinProperty[];
  onSaved: () => void;
};

export default function PinTags({ pin, map, pinProperties, onSaved }: Props) {
  const dictionary = useDictionary();
  const menuId = useId();

  const [stored, setStored] = useState(storedTags(pin));
  const [shownPin, setShownPin] = useState(pin);
  const [pendingIds, setPendingIds] = useState<number[] | null>(null);
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const [managing, setManaging] = useState(false);

  if (pin !== shownPin) {
    setShownPin(pin);
    setStored(newer(stored, storedTags(pin)));
  }

  const optionIds = pendingIds ?? stored.ids;
  const saving = pendingIds !== null;

  const offeredProperties = pinProperties.filter(
    (property) => property.options.length > 0
  );

  const toggle = async (property: PinProperty, optionId: number) => {
    const next = toggleOption(optionIds, property, optionId);

    setPendingIds(next);

    const result = await updatePinPropertyOptions(
      pin.map.id,
      pin.id,
      offeredOptionIds(pinProperties, next)
    ).catch(() => ({ success: false, data: undefined, error: undefined }));

    setPendingIds(null);

    if (result.success && result.data) {
      const saved = storedTags(result.data);
      setStored((current) => newer(current, saved));
      onSaved();
      return;
    }

    enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
      variant: 'error'
    });
  };

  const openManagement = () => {
    setAnchorEl(null);
    setManaging(true);
  };

  if (!map?.editable) {
    return (
      <PinPropertyValues optionIds={optionIds} pinProperties={pinProperties} />
    );
  }

  return (
    <>
      <PinPropertyValues
        optionIds={optionIds}
        pinProperties={pinProperties}
        action={
          <Chip
            variant="outlined"
            icon={<Add />}
            label={dictionary['add pin property option']}
            aria-haspopup="menu"
            aria-expanded={Boolean(anchorEl)}
            aria-controls={anchorEl ? menuId : undefined}
            onClick={(event) => setAnchorEl(event.currentTarget)}
          />
        }
      />
      <Menu
        id={menuId}
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
      >
        {offeredProperties.flatMap((property) => [
          <ListSubheader key={`property-${property.id}`}>
            {property.name}
          </ListSubheader>,
          ...property.options.map((option) => {
            const chosen = optionIds.includes(option.id);

            return (
              <MenuItem
                key={option.id}
                role="menuitemcheckbox"
                aria-checked={chosen}
                selected={chosen}
                disabled={saving}
                onClick={() => toggle(property, option.id)}
              >
                <ListItemIcon>
                  <PinPropertyIcon icon={optionIcon(property, option)} />
                </ListItemIcon>
                <ListItemText primary={option.name} />
                {chosen && <Check fontSize="small" />}
              </MenuItem>
            );
          })
        ])}
        {offeredProperties.length > 0 && <Divider />}
        <MenuItem onClick={openManagement}>
          <ListItemIcon>
            <Sell fontSize="small" />
          </ListItemIcon>
          <ListItemText primary={dictionary['pin properties']} />
        </MenuItem>
      </Menu>
      <PinPropertiesDialog
        open={managing}
        onClose={() => setManaging(false)}
        map={map}
        pinProperties={pinProperties}
      />
    </>
  );
}
