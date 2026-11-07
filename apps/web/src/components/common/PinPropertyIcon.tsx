import { Sell } from '@mui/icons-material';
import { Box } from '@mui/material';

type Props = {
  icon: string | null;
};

export default function PinPropertyIcon({ icon }: Props) {
  if (!icon) {
    return <Sell fontSize="small" />;
  }

  return (
    <Box
      component="span"
      aria-hidden
      sx={{ fontSize: 18, lineHeight: 1, width: '1em', textAlign: 'center' }}
    >
      {icon}
    </Box>
  );
}
