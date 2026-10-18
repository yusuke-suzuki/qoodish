'use client';

import {
  Delete,
  DirectionsWalk,
  HistoryEdu,
  MoreVert
} from '@mui/icons-material';
import {
  Box,
  Button,
  Chip,
  Fab,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Paper
} from '@mui/material';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { type MouseEvent, useState } from 'react';
import type { JourneySummary } from '../../../types/index.ts';
import { deleteJourney } from '../../actions/journeys.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalDateTime from '../../hooks/useLocalDateTime.ts';
import ConfirmDeleteDialog from '../common/ConfirmDeleteDialog.tsx';
import DiscoverButton from '../common/DiscoverButton.tsx';
import NoContents from '../common/NoContents.tsx';
import RecordPastJourneyDialog from '../journeys/RecordPastJourneyDialog.tsx';
import { BOTTOM_NAV_HEIGHT } from '../layouts/BottomNav.tsx';

const FAB_CLEARANCE = 10;

const DATE_TIME_OPTIONS: Intl.DateTimeFormatOptions = {
  year: 'numeric',
  month: 'short',
  day: 'numeric',
  hour: '2-digit',
  minute: '2-digit'
};

function UserJourneys({
  journeys: initialJourneys
}: {
  journeys: JourneySummary[];
}) {
  const dictionary = useDictionary();
  const { lang } = useParams<{ lang: string }>();
  const formatLocal = useLocalDateTime();
  const router = useRouter();

  const [deletedIds, setDeletedIds] = useState<Set<number>>(new Set());
  const [importOpen, setImportOpen] = useState(false);
  const [menuAnchor, setMenuAnchor] = useState<HTMLElement | null>(null);
  const [menuJourney, setMenuJourney] = useState<JourneySummary | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<JourneySummary | null>(null);

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

          <Paper variant="outlined" sx={{ mb: FAB_CLEARANCE }}>
            <List disablePadding>
              {journeys.map((journey, index) => {
                const started = Boolean(journey.started_at);
                const active = started && !journey.finished_at;
                const dateSource =
                  journey.finished_at ??
                  journey.started_at ??
                  journey.created_at;

                return (
                  <ListItem
                    key={journey.id}
                    disablePadding
                    divider={index < journeys.length - 1}
                  >
                    <ListItemButton
                      component={Link}
                      href={`/${lang}/journeys/${journey.id}`}
                      sx={{ flex: 1, minWidth: 0 }}
                    >
                      <ListItemIcon sx={{ minWidth: 40 }}>
                        <DirectionsWalk fontSize="small" color="action" />
                      </ListItemIcon>
                      <ListItemText
                        primary={formatLocal(dateSource, DATE_TIME_OPTIONS)}
                        secondary={
                          <>
                            {journey.map?.name && (
                              <Box
                                component="span"
                                sx={{
                                  display: 'block',
                                  overflow: 'hidden',
                                  textOverflow: 'ellipsis',
                                  whiteSpace: 'nowrap'
                                }}
                              >
                                {journey.map.name}
                              </Box>
                            )}
                            <Box component="span" sx={{ display: 'block' }}>
                              {started
                                ? dictionary['checkins count'].replace(
                                    '{count}',
                                    String(journey.checkins_count)
                                  )
                                : dictionary['milestones count'].replace(
                                    '{count}',
                                    String(journey.milestones_count)
                                  )}
                            </Box>
                          </>
                        }
                        slotProps={{ primary: { noWrap: true } }}
                      />
                      {active && (
                        <Chip
                          label={dictionary['in progress']}
                          size="small"
                          color="primary"
                          sx={{ ml: 1, flexShrink: 0 }}
                        />
                      )}
                      {!started && (
                        <Chip
                          label={dictionary.planned}
                          size="small"
                          sx={{ ml: 1, flexShrink: 0 }}
                        />
                      )}
                    </ListItemButton>

                    <IconButton
                      aria-label={dictionary.more}
                      onClick={(event) => openMenu(event, journey)}
                      sx={{ mr: 0.5 }}
                    >
                      <MoreVert />
                    </IconButton>
                  </ListItem>
                );
              })}
            </List>
          </Paper>
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
