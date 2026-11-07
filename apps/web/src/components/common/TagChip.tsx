import { Chip, type ChipProps, type SxProps, type Theme } from '@mui/material';

type Props = ChipProps & {
  tagColor: string | null;
};

function tagColorSx(tagColor: string, outlined: boolean): SxProps<Theme> {
  if (outlined) {
    return { borderColor: tagColor };
  }

  return (theme) => {
    const palette = theme.palette.augmentColor({ color: { main: tagColor } });

    return {
      bgcolor: palette.main,
      color: palette.contrastText,
      '& .MuiChip-icon': { color: 'inherit' },
      '&.MuiChip-clickable:hover, &.Mui-focusVisible': { bgcolor: palette.dark }
    };
  };
}

export default function TagChip({ tagColor, variant, ...props }: Props) {
  return (
    <Chip
      variant={variant}
      sx={tagColor ? tagColorSx(tagColor, variant === 'outlined') : undefined}
      {...props}
    />
  );
}
