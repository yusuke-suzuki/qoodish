'use client';

import {
  Check,
  DarkMode,
  LightMode,
  SettingsBrightness
} from '@mui/icons-material';
import {
  IconButton,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  useColorScheme
} from '@mui/material';
import { useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';

type Mode = 'system' | 'light' | 'dark';

const MODE_ICONS = {
  system: SettingsBrightness,
  light: LightMode,
  dark: DarkMode
};

type Props = {
  // The bar shows an icon alone, so the label has to live in a tooltip there.
  variant: 'list' | 'bar';
  onSelect?: () => void;
};

export default function ThemeMenuButton({ variant, onSelect }: Props) {
  const dictionary = useDictionary();
  // Undefined until the provider has read the stored choice after mounting.
  const { mode, setMode } = useColorScheme();

  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const options: { mode: Mode; label: string }[] = [
    { mode: 'system', label: dictionary['system theme'] },
    { mode: 'light', label: dictionary['light theme'] },
    { mode: 'dark', label: dictionary['dark theme'] }
  ];

  const handleSelect = (selected: Mode) => {
    setMode(selected);
    setAnchorEl(null);
    onSelect?.();
  };

  const ModeIcon = MODE_ICONS[mode ?? 'system'];

  return (
    <>
      {variant === 'bar' ? (
        <IconButton
          onClick={(event) => setAnchorEl(event.currentTarget)}
          title={dictionary.theme}
          aria-label={dictionary.theme}
        >
          <ModeIcon />
        </IconButton>
      ) : (
        <ListItemButton
          dense
          onClick={(event) => setAnchorEl(event.currentTarget)}
          title={dictionary.theme}
        >
          <ListItemText
            primary={dictionary.theme}
            slotProps={{ primary: { color: 'text.secondary' } }}
          />
        </ListItemButton>
      )}

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
      >
        {options.map((option) => (
          <MenuItem
            key={option.mode}
            selected={option.mode === mode}
            onClick={() => handleSelect(option.mode)}
          >
            <ListItemIcon>
              {option.mode === mode && <Check fontSize="small" />}
            </ListItemIcon>
            <ListItemText primary={option.label} />
          </MenuItem>
        ))}
      </Menu>
    </>
  );
}
