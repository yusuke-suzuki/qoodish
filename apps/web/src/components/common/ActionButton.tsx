import { IconButton, Stack, Typography } from '@mui/material';
import type { ReactNode } from 'react';

type Props = {
  icon: ReactNode;
  label: string;
  onClick: () => void;
  active?: boolean;
  disabled?: boolean;
  loading?: boolean;
};

export default function ActionButton({
  icon,
  label,
  onClick,
  active,
  disabled,
  loading
}: Props) {
  return (
    <Stack alignItems="center" spacing={0.5}>
      <IconButton
        disabled={disabled}
        loading={loading}
        onClick={onClick}
        aria-label={label}
        aria-pressed={active}
        sx={(theme) => {
          const { action, secondary } = (theme.vars ?? theme).palette;

          return active
            ? {
                color: secondary.contrastText,
                bgcolor: secondary.main,
                '&:hover': { bgcolor: secondary.dark }
              }
            : {
                color: secondary.main,
                bgcolor: theme.alpha(secondary.main, action.selectedOpacity),
                '&:hover': {
                  bgcolor: theme.alpha(
                    secondary.main,
                    `${action.selectedOpacity} + ${action.hoverOpacity}`
                  )
                },
                '&.Mui-disabled': { bgcolor: action.disabledBackground }
              };
        }}
      >
        {icon}
      </IconButton>
      <Typography
        variant="caption"
        color={disabled ? 'text.disabled' : 'text.secondary'}
        aria-hidden
      >
        {label}
      </Typography>
    </Stack>
  );
}
