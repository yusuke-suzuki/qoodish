'use client';

import { Drafts } from '@mui/icons-material';
import {
  Avatar,
  List,
  ListItemAvatar,
  ListItemButton,
  ListItemText,
  Paper
} from '@mui/material';
import Link from 'next/link';
import type { CoauthorshipInvitation } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalePath from '../../hooks/useLocalePath.ts';
import NoContents from '../common/NoContents.tsx';

type Props = {
  invitations: CoauthorshipInvitation[];
};

function AcceptedInvitationList({ invitations }: Props) {
  const dictionary = useDictionary();
  const localePath = useLocalePath();

  if (invitations.length < 1) {
    return (
      <NoContents
        icon={Drafts}
        message={dictionary['no accepted invites here']}
      />
    );
  }

  return (
    <Paper variant="outlined">
      <List disablePadding>
        {invitations.map((invitation) => (
          <ListItemButton
            key={invitation.id}
            LinkComponent={Link}
            href={localePath(`/maps/${invitation.map.id}`)}
          >
            <ListItemAvatar>
              <Avatar
                variant="rounded"
                src={invitation.map.image?.avatar}
                alt={invitation.map.name}
              />
            </ListItemAvatar>
            <ListItemText
              primary={invitation.map.name}
              secondary={dictionary['accepted invitation message'].replace(
                '{name}',
                invitation.inviter.name
              )}
            />
          </ListItemButton>
        ))}
      </List>
    </Paper>
  );
}

export default AcceptedInvitationList;
