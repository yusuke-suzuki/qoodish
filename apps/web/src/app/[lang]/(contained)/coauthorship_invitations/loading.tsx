import {
  Box,
  Card,
  CardActions,
  CardHeader,
  Skeleton,
  Stack
} from '@mui/material';

const PLACEHOLDER_COUNT = 5;
const TAB_COUNT = 2;
const tabBarHeight = 48;

export default function Loading() {
  return (
    <>
      {/* Plain boxes rather than Tabs: a skeleton must not expose focusable
          tab roles that carry no accessible name. */}
      <Card>
        <Box
          sx={{
            height: tabBarHeight,
            display: 'grid',
            gridTemplateColumns: `repeat(${TAB_COUNT}, 1fr)`,
            alignItems: 'center',
            justifyItems: 'center'
          }}
        >
          {Array.from({ length: TAB_COUNT }).map((_, index) => (
            <Skeleton
              // biome-ignore lint/suspicious/noArrayIndexKey: static skeleton list
              key={`skeleton-invitation-tab-${index}`}
              variant="text"
              width={48}
            />
          ))}
        </Box>
      </Card>

      <Stack spacing={2} sx={{ mt: 3 }}>
        {Array.from({ length: PLACEHOLDER_COUNT }).map((_, index) => (
          <Card
            // biome-ignore lint/suspicious/noArrayIndexKey: static skeleton list
            key={`skeleton-invitation-${index}`}
            variant="outlined"
          >
            <CardHeader
              avatar={<Skeleton variant="rounded" width={40} height={40} />}
              title={<Skeleton variant="text" width="60%" />}
              subheader={<Skeleton variant="text" width="40%" />}
            />
            <CardActions sx={{ justifyContent: 'flex-end', px: 2, pb: 2 }}>
              <Skeleton variant="rounded" width={72} height={32} />
              <Skeleton variant="rounded" width={88} height={32} />
            </CardActions>
          </Card>
        ))}
      </Stack>
    </>
  );
}
