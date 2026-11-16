import { Card, CardActions, CardContent, Grid, Skeleton } from '@mui/material';
import { PageHeaderSkeleton } from '../../../../../components/common/PageHeader.tsx';
import {
  JOURNEY_CARD_SIZE,
  JOURNEY_COVER_HEIGHT
} from '../../../../../components/journeys/journeyCardLayout.ts';

const CARD_COUNT = 4;

export default function Loading() {
  return (
    <>
      <PageHeaderSkeleton />

      <Grid container spacing={2}>
        {Array.from({ length: CARD_COUNT }).map((_, index) => (
          <Grid
            // biome-ignore lint/suspicious/noArrayIndexKey: static skeleton list
            key={`skeleton-journey-${index}`}
            size={JOURNEY_CARD_SIZE}
          >
            <Card variant="outlined">
              <Skeleton variant="rectangular" height={JOURNEY_COVER_HEIGHT} />
              <CardContent>
                <Skeleton
                  variant="text"
                  width="70%"
                  sx={{ typography: 'subtitle1' }}
                />
                <Skeleton variant="text" width="40%" />
                <Skeleton variant="text" width="30%" />
              </CardContent>
              <CardActions>
                <Skeleton variant="rounded" width={140} height={36} />
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>
    </>
  );
}
