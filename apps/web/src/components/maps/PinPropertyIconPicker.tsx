'use client';

import { IconButton, Popover } from '@mui/material';
import { useId, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';
import EmojiPicker, { EMOJI_CELL_SIZE } from '../common/EmojiPicker.tsx';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';

type Props = {
  icon: string | null;
  disabled?: boolean;
  onChange: (icon: string | null) => void;
};

export default function PinPropertyIconPicker({
  icon,
  disabled,
  onChange
}: Props) {
  const dictionary = useDictionary();
  const popoverId = useId();

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);

  const open = Boolean(anchorEl);

  const choose = (next: string | null) => {
    setAnchorEl(null);

    if (next !== icon) {
      onChange(next);
    }
  };

  return (
    <>
      <IconButton
        aria-label={dictionary['change pin property icon']}
        title={dictionary['change pin property icon']}
        aria-haspopup="true"
        aria-expanded={open}
        aria-controls={open ? popoverId : undefined}
        disabled={disabled}
        onClick={(event) => setAnchorEl(event.currentTarget)}
        sx={{
          width: EMOJI_CELL_SIZE,
          height: EMOJI_CELL_SIZE,
          border: 1,
          borderColor: 'divider'
        }}
      >
        <PinPropertyIcon icon={icon} />
      </IconButton>
      <Popover
        id={popoverId}
        open={open}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
      >
        <EmojiPicker
          value={icon}
          onSelect={choose}
          leading={
            <IconButton
              aria-label={dictionary['no icon']}
              aria-pressed={icon === null}
              onClick={() => choose(null)}
              sx={{
                width: EMOJI_CELL_SIZE,
                height: EMOJI_CELL_SIZE,
                bgcolor: icon === null ? 'action.selected' : undefined
              }}
            >
              <PinPropertyIcon icon={null} />
            </IconButton>
          }
        />
      </Popover>
    </>
  );
}
