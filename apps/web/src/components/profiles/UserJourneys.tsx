'use client';

import { Delete, DirectionsWalk, HistoryEdu } from '@mui/icons-material';
import {
  Button,
  Fab,
  Grid,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem
} from '@mui/material';
import { useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { type MouseEvent, useState } from 'react';
import type { JourneySummary } from '../../../types/index.ts';
import { deleteJourney } from '../../actions/journeys.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useWriteJourneyChapter from '../../hooks/useWriteJourneyChapter.ts';
import ConfirmDeleteDialog from '../common/ConfirmDeleteDialog.tsx';
import DiscoverButton from '../common/DiscoverButton.tsx';
import NoContents from '../common/NoContents.tsx';
import JourneyCard from '../journeys/JourneyCard.tsx';
import { JOURNEY_CARD_SIZE } from '../journeys/journeyCardLayout.ts';
import RecordPastJourneyDialog from '../journeys/RecordPastJourneyDialog.tsx';
import { BOTTOM_NAV_HEIGHT } from '../layouts/BottomNav.tsx';

const FAB_CLEARANCE = 10;

function UserJourneys({
  journeys: initialJourneys
}: {
  journeys: JourneySummary[];
}) {
  const dictionary = useDictionary();
  const router = useRouter();

  const [deletedIds, setDeletedIds] = useState<Set<number>>(new Set());
  const [importOpen, setImportOpen] = useState(false);
  const [menuAnchor, setMenuAnchor] = useState<HTMLElement | null>(null);
  const [menuJourney, setMenuJourney] = useState<JourneySummary | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<JourneySummary | null>(null);
  const { writingId, write } = useWriteJourneyChapter();

  const openMenu = (
    event: MouseEvent<HTMLElement>,
    journey: JourneySummary
  ) => {
    setMenuAnchor(event.currentTarget);
    setMenuJourney(journey);
  };

  const closeMenu = () => setMenuAnchor(null);

  const handleDeleteClick = () => {
    setDeleteTarget(menuJourney);
    closeMenu();
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) {
      return;
    }

    const target = deleteTarget;
    const { success } = await deleteJourney(target.id);

    if (!success) {
      enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
      return;
    }

    setDeletedIds((current) => new Set(current).add(target.id));
    enqueueSnackbar(dictionary['delete journey success'], {
      variant: 'success'
    });
    setDeleteTarget(null);
    router.refresh();
  };

  const journeys = initialJourneys.filter(
    (journey) => !deletedIds.has(journey.id)
  );

  return (
    <>
      {journeys.length < 1 ? (
        <NoContents
          icon={DirectionsWalk}
          message={dictionary['journeys will see here']}
          action={
            <>
              <Button
                variant="contained"
                color="secondary"
                disableElevation
                onClick={() => setImportOpen(true)}
                startIcon={<HistoryEdu />}
              >
                {dictionary['record past journey']}
              </Button>
              <DiscoverButton />
            </>
          }
        />
      ) : (
        <>
          <Fab
            variant="extended"
            color="secondary"
            onClick={() => setImportOpen(true)}
            sx={{
              position: 'fixed',
              right: 16,
              bottom: { xs: BOTTOM_NAV_HEIGHT + 16, md: 16 }
            }}
          >
            <HistoryEdu sx={{ mr: 1 }} />
            {dictionary['record past journey']}
          </Fab>

          <Grid container spacing={2} sx={{ mb: FAB_CLEARANCE }}>
            {journeys.map((journey) => (
              <Grid key={journey.id} size={JOURNEY_CARD_SIZE}>
                <JourneyCard
                  journey={journey}
                  writing={writingId === journey.id}
                  writeDisabled={writingId !== null}
                  onWrite={(journey) => write(journey.id)}
                  onMore={openMenu}
                />
              </Grid>
            ))}
          </Grid>
        </>
      )}

      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={closeMenu}
      >
        <MenuItem onClick={handleDeleteClick}>
          <ListItemIcon>
            <Delete fontSize="small" />
          </ListItemIcon>
          <ListItemText primary={dictionary.delete} />
        </MenuItem>
      </Menu>

      <RecordPastJourneyDialog
        open={importOpen}
        onClose={() => setImportOpen(false)}
      />

      <ConfirmDeleteDialog
        open={Boolean(deleteTarget)}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDeleteConfirm}
        title={dictionary['sure to delete journey']}
      />
    </>
  );
}

export default UserJourneys;
