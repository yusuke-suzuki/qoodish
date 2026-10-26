import { IconButton, type IconButtonProps } from '@mui/material';

// The Maps API draws its own controls at 18px from the breakpoint where it
// shows them, and these buttons stand in the same row.
export const GLYPH_SIZE = { xs: 20, md: 18 };

type Props = Omit<IconButtonProps, 'sx' | 'aria-label' | 'title'> & {
  label: string;
};

function MapControlButton({ label, ...props }: Props) {
  return (
    <IconButton
      {...props}
      aria-label={label}
      title={label}
      // Fixed colors rather than theme tokens: the button sits among the
      // Maps API's own controls, which keep their palette in every theme.
      sx={{
        width: 40,
        height: 40,
        borderRadius: '50%',
        bgcolor: '#fff',
        color: '#666',
        boxShadow: '0 1px 4px -1px rgba(0,0,0,0.3)',
        '&:hover': {
          bgcolor: '#fff',
          color: '#333'
        }
      }}
    />
  );
}

export default MapControlButton;
