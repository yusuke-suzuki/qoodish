'use client';

import { TabContext, TabList, TabPanel } from '@mui/lab';
import { Card, Tab } from '@mui/material';
import { type SyntheticEvent, useState } from 'react';
import type { CoauthorshipInvitation } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import AcceptedInvitationList from './AcceptedInvitationList.tsx';
import CoauthorshipInvitationList from './CoauthorshipInvitationList.tsx';

type Props = {
  pending: CoauthorshipInvitation[];
  accepted: CoauthorshipInvitation[];
};

function CoauthorshipInvitationsView({ pending, accepted }: Props) {
  const dictionary = useDictionary();
  const [tabValue, setTabValue] = useState('pending');

  const handleTabChange = (
    _event: SyntheticEvent<Element, Event>,
    newValue: string
  ) => {
    setTabValue(newValue);
  };

  return (
    <TabContext value={tabValue}>
      <Card>
        <TabList onChange={handleTabChange} variant="fullWidth">
          <Tab label={dictionary['pending invitations']} value="pending" />
          <Tab label={dictionary['accepted invitations']} value="accepted" />
        </TabList>
      </Card>

      <TabPanel value="pending" sx={{ px: 0 }}>
        <CoauthorshipInvitationList invitations={pending} />
      </TabPanel>
      <TabPanel value="accepted" sx={{ px: 0 }}>
        <AcceptedInvitationList invitations={accepted} />
      </TabPanel>
    </TabContext>
  );
}

export default CoauthorshipInvitationsView;
