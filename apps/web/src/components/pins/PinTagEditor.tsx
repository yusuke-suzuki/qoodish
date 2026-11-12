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
import { useId, useState } from 'react';
import type { AppMap, PinProperty } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import { optionIcon } from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';
import PinPropertyValues from '../common/PinPropertyValues.tsx';
import PinPropertiesDialog from '../maps/PinPropertiesDialog.tsx';

type Props = {
  map: AppMap | null;
  pinProperties: PinProperty[];
  value: number[];
  disabled?: boolean;
  onToggle: (property: PinProperty, optionId: number) => void;
};

export default function PinTagEditor({
  map,
  pinProperties,
  value,
  disabled,
  onToggle
}: Props) {
  const dictionary = useDictionary();
  const menuId = useId();

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const [managing, setManaging] = useState(false);

  const offeredProperties = pinProperties.filter(
    (property) => property.options.length > 0
  );

  const openManagement = () => {
    setAnchorEl(null);
    setManaging(true);
  };

  return (
    <>
      <PinPropertyValues
        optionIds={value}
        pinProperties={pinProperties}
        disabled={disabled}
        onDelete={onToggle}
        action={
          <Chip
            variant="outlined"
            icon={<Add />}
            label={dictionary['add pin property option']}
            aria-haspopup="menu"
            aria-expanded={Boolean(anchorEl)}
            aria-controls={anchorEl ? menuId : undefined}
            disabled={disabled}
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
        {offeredProperties.flatMap((property, index) => [
          ...(index > 0 ? [<Divider key={`divider-${property.id}`} />] : []),
          <ListSubheader key={`property-${property.id}`}>
            {property.name}
          </ListSubheader>,
          ...property.options.map((option) => {
            const chosen = value.includes(option.id);

            return (
              <MenuItem
                key={option.id}
                role={property.multiple ? 'menuitemcheckbox' : 'menuitemradio'}
                aria-checked={chosen}
                selected={chosen}
                disabled={disabled}
                onClick={() => onToggle(property, option.id)}
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
        {map?.editable && offeredProperties.length > 0 && <Divider />}
        {map?.editable && (
          <MenuItem disabled={disabled} onClick={openManagement}>
            <ListItemIcon>
              <Sell fontSize="small" />
            </ListItemIcon>
            <ListItemText primary={dictionary['pin properties']} />
          </MenuItem>
        )}
      </Menu>
      {map?.editable && (
        <PinPropertiesDialog
          open={managing}
          onClose={() => setManaging(false)}
          map={map}
          pinProperties={pinProperties}
        />
      )}
    </>
  );
}
