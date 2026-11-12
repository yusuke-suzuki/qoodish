import {
  alpha,
  Chip,
  type ChipProps,
  type SxProps,
  type Theme
} from '@mui/material';

type Props = ChipProps & {
  tagColor: string | null;
};

type SxEntry = Exclude<SxProps<Theme>, readonly unknown[]>;

export function tagPalette(theme: Theme, tagColor: string) {
  return theme.palette.augmentColor({ color: { main: tagColor } });
}

function tagColorSx(tagColor: string | null, outlined: boolean): SxEntry {
  if (!tagColor) {
    return {};
  }

  if (outlined) {
    return { borderColor: tagColor };
  }

  return (theme) => {
    const palette = tagPalette(theme, tagColor);

    return {
      bgcolor: palette.main,
      color: palette.contrastText,
      '& .MuiChip-icon': { color: 'inherit' },
      '& .MuiChip-deleteIcon': {
        color: alpha(palette.contrastText, 0.7),
        '&:hover': { color: palette.contrastText }
      },
      '&.MuiChip-clickable:hover, &.Mui-focusVisible': { bgcolor: palette.dark }
    };
  };
}

export default function TagChip({ tagColor, variant, sx, ...props }: Props) {
  return (
    <Chip
      variant={variant}
      {...props}
      sx={[
        tagColorSx(tagColor, variant === 'outlined'),
        ...(Array.isArray(sx) ? sx : [sx])
      ]}
    />
  );
}
