import { Box } from '@mui/material';
import { EMOJI_CELL_SIZE } from '../common/EmojiPicker.tsx';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';

export default function PinPropertyIconCell({ icon }: { icon: string | null }) {
  return (
    <Box
      sx={{
        width: EMOJI_CELL_SIZE,
        height: EMOJI_CELL_SIZE,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}
    >
      <PinPropertyIcon icon={icon} />
    </Box>
  );
}
