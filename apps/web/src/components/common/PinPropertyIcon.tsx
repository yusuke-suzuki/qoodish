import { Sell } from '@mui/icons-material';
import { Box } from '@mui/material';

type Props = {
  icon: string | null;
  className?: string;
};

export default function PinPropertyIcon({ icon, className }: Props) {
  if (!icon) {
    return <Sell fontSize="small" className={className} />;
  }

  return (
    <Box
      component="span"
      aria-hidden
      className={className}
      sx={{ fontSize: 18, lineHeight: 1 }}
    >
      {icon}
    </Box>
  );
}
