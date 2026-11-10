'use client';

import { Check, Circle, Palette } from '@mui/icons-material';
import { Box, IconButton, Popover } from '@mui/material';
import {
  amber,
  blue,
  blueGrey,
  brown,
  cyan,
  deepOrange,
  deepPurple,
  green,
  indigo,
  lightBlue,
  lime,
  orange,
  pink,
  purple,
  red,
  teal
} from '@mui/material/colors';
import { useId, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';
import { tagPalette } from '../common/TagChip.tsx';

const SWATCHES = (
  [
    ['red', red],
    ['pink', pink],
    ['purple', purple],
    ['deepPurple', deepPurple],
    ['indigo', indigo],
    ['blue', blue],
    ['lightBlue', lightBlue],
    ['cyan', cyan],
    ['teal', teal],
    ['green', green],
    ['lime', lime],
    ['amber', amber],
    ['orange', orange],
    ['deepOrange', deepOrange],
    ['brown', brown],
    ['blueGrey', blueGrey]
  ] as const
).map(([name, hue]) => ({ name, color: hue[600].toLowerCase() }));

const DEFAULT_CUSTOM_COLOR = '#1e88e5';

type Props = {
  color: string | null;
  disabled?: boolean;
  onChange: (color: string | null) => void;
};

export default function PinPropertyColorPicker({
  color,
  disabled,
  onChange
}: Props) {
  const dictionary = useDictionary();
  const popoverId = useId();

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const [custom, setCustom] = useState(DEFAULT_CUSTOM_COLOR);

  const open = (target: HTMLElement) => {
    setCustom(color ?? DEFAULT_CUSTOM_COLOR);
    setAnchorEl(target);
  };

  const customColor =
    color && !SWATCHES.some((swatch) => swatch.color === color) ? color : null;

  const choose = (next: string | null) => {
    setAnchorEl(null);

    if (next !== color) {
      onChange(next);
    }
  };

  const customInputRef = (input: HTMLInputElement | null) => {
    if (!input) {
      return;
    }

    const handleCommit = () => choose(input.value.toLowerCase());

    input.addEventListener('change', handleCommit);

    return () => input.removeEventListener('change', handleCommit);
  };

  return (
    <>
      <IconButton
        aria-label={dictionary['change pin property color']}
        title={dictionary['change pin property color']}
        aria-haspopup="true"
        aria-expanded={Boolean(anchorEl)}
        aria-controls={anchorEl ? popoverId : undefined}
        disabled={disabled}
        onClick={(event) => open(event.currentTarget)}
      >
        <Circle sx={{ color: color ?? 'action.selected' }} />
      </IconButton>
      <Popover
        id={popoverId}
        open={Boolean(anchorEl)}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Box sx={{ p: 1.5, width: 296, maxWidth: '100%' }}>
          <Box
            role="group"
            aria-label={dictionary['change pin property color']}
            sx={{
              display: 'grid',
              gridTemplateColumns: 'repeat(6, 1fr)',
              gap: 0.5
            }}
          >
            <IconButton
              aria-label={dictionary['no color']}
              aria-pressed={color === null}
              onClick={() => choose(null)}
              sx={{
                width: 40,
                height: 40,
                justifySelf: 'center',
                bgcolor: 'action.selected'
              }}
            >
              <Check
                fontSize="small"
                sx={{ visibility: color === null ? 'visible' : 'hidden' }}
              />
            </IconButton>
            {SWATCHES.map((swatch) => (
              <IconButton
                key={swatch.name}
                aria-label={dictionary[`color ${swatch.name}`]}
                title={dictionary[`color ${swatch.name}`]}
                aria-pressed={swatch.color === color}
                onClick={() => choose(swatch.color)}
                sx={(theme) => ({
                  width: 40,
                  height: 40,
                  justifySelf: 'center',
                  bgcolor: swatch.color,
                  color: tagPalette(theme, swatch.color).contrastText,
                  '&:hover': { bgcolor: tagPalette(theme, swatch.color).dark }
                })}
              >
                <Check
                  fontSize="small"
                  sx={{
                    visibility: swatch.color === color ? 'visible' : 'hidden'
                  }}
                />
              </IconButton>
            ))}
            <Box
              sx={(theme) => ({
                position: 'relative',
                width: 40,
                height: 40,
                justifySelf: 'center',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                borderRadius: '50%',
                bgcolor: customColor ?? 'action.selected',
                color: customColor
                  ? tagPalette(theme, customColor).contrastText
                  : 'text.primary',
                '&:focus-within': {
                  outline: 2,
                  outlineColor: theme.palette.primary.main
                }
              })}
            >
              {customColor ? <Check fontSize="small" /> : <Palette />}
              <Box
                component="input"
                type="color"
                aria-label={dictionary['custom color']}
                value={custom}
                onChange={(event) => setCustom(event.target.value)}
                ref={customInputRef}
                sx={{
                  position: 'absolute',
                  inset: 0,
                  width: '100%',
                  height: '100%',
                  opacity: 0,
                  cursor: 'pointer',
                  border: 0,
                  p: 0
                }}
              />
            </Box>
          </Box>
        </Box>
      </Popover>
    </>
  );
}
