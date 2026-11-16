import {
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Skeleton
} from '@mui/material';
import { PageHeaderSkeleton } from '../../../../components/common/PageHeader.tsx';

const PLACEHOLDER_COUNT = 8;

export default function Loading() {
  return (
    <>
      <PageHeaderSkeleton />
      <List>
        {Array.from({ length: PLACEHOLDER_COUNT }).map((_, index) => (
          <ListItem
            // biome-ignore lint/suspicious/noArrayIndexKey: static skeleton list
            key={`skeleton-notification-${index}`}
            dense
            secondaryAction={
              <Skeleton variant="rounded" width={40} height={40} />
            }
          >
            <ListItemAvatar>
              <Skeleton variant="circular" width={40} height={40} />
            </ListItemAvatar>
            <ListItemText
              disableTypography
              primary={<Skeleton variant="text" width="80%" />}
              secondary={<Skeleton variant="text" width="35%" />}
            />
          </ListItem>
        ))}
      </List>
    </>
  );
}
