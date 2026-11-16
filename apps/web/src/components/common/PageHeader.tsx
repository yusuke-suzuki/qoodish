import { Skeleton, Typography } from '@mui/material';

const headerSx = { mb: 3 };

export default function PageHeader({ title }: { title: string }) {
  return (
    <Typography variant="h5" component="h1" sx={headerSx}>
      {title}
    </Typography>
  );
}

export function PageHeaderSkeleton() {
  return (
    <Skeleton
      variant="text"
      width={160}
      sx={{ ...headerSx, typography: 'h5' }}
    />
  );
}
