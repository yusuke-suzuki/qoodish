import { Avatar, Link as MuiLink, type SxProps } from '@mui/material';
import type { UserSummary } from '../../../types/index.ts';
import useLocalePath from '../../hooks/useLocalePath.ts';
import Link from './Link.tsx';

type Props = {
  author: UserSummary;
  sx?: SxProps;
};

export default function AuthorAvatar({ author, sx }: Props) {
  const localePath = useLocalePath();

  return (
    <MuiLink
      component={Link}
      underline="none"
      href={localePath(`/users/${author.id}`)}
      title={author.name}
    >
      <Avatar
        src={author.image?.avatar}
        alt={author.name}
        sx={sx}
        slotProps={{
          img: {
            loading: 'lazy'
          }
        }}
      />
    </MuiLink>
  );
}
