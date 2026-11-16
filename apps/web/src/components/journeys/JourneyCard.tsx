'use client';

import { DirectionsWalk, HistoryEdu, MoreVert } from '@mui/icons-material';
import {
  Box,
  Button,
  Card,
  CardActionArea,
  CardActions,
  CardContent,
  CardMedia,
  Chip,
  IconButton,
  Stack,
  Typography
} from '@mui/material';
import { useParams } from 'next/navigation';
import type { MouseEvent } from 'react';
import type { JourneySummary } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalDateTime from '../../hooks/useLocalDateTime.ts';
import { journeyHeadline } from '../../utils/journeyHeadline.ts';
import {
  CARD_GRID_SIZES,
  responsiveImage
} from '../../utils/responsiveImage.ts';
import Link from '../common/Link.tsx';
import { JOURNEY_COVER_HEIGHT } from './journeyCardLayout.ts';

const DATE_OPTIONS: Intl.DateTimeFormatOptions = {
  year: 'numeric',
  month: 'long',
  day: 'numeric'
};

type Props = {
  journey: JourneySummary;
  writing: boolean;
  writeDisabled: boolean;
  onWrite: (journey: JourneySummary) => void;
  onMore: (event: MouseEvent<HTMLElement>, journey: JourneySummary) => void;
};

function JourneyCover({ journey }: { journey: JourneySummary }) {
  if (journey.cover_image) {
    return (
      <CardMedia
        component="img"
        {...responsiveImage(journey.cover_image, CARD_GRID_SIZES)}
        alt=""
        loading="lazy"
        sx={{ height: JOURNEY_COVER_HEIGHT, objectFit: 'cover' }}
      />
    );
  }

  return (
    <Box
      sx={{
        height: JOURNEY_COVER_HEIGHT,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'action.hover'
      }}
    >
      <DirectionsWalk fontSize="large" color="disabled" />
    </Box>
  );
}

export default function JourneyCard({
  journey,
  writing,
  writeDisabled,
  onWrite,
  onMore
}: Props) {
  const dictionary = useDictionary();
  const { lang } = useParams<{ lang: string }>();
  const formatLocal = useLocalDateTime();

  const started = Boolean(journey.started_at);
  const active = started && !journey.finished_at;
  const { chapter } = journey;
  const writable = Boolean(journey.finished_at && journey.map && !chapter);

  return (
    <Card
      variant="outlined"
      sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}
    >
      <CardActionArea
        component={Link}
        href={`/${lang}/journeys/${journey.id}`}
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'stretch'
        }}
      >
        <JourneyCover journey={journey} />
        <Stack
          direction="row"
          spacing={1}
          useFlexGap
          flexWrap="wrap"
          sx={{ position: 'absolute', top: 8, left: 8, right: 8 }}
        >
          {active && (
            <Chip
              label={dictionary['in progress']}
              size="small"
              color="primary"
            />
          )}
          {!started && <Chip label={dictionary.planned} size="small" />}
          {chapter && (
            <Chip
              icon={<HistoryEdu fontSize="small" />}
              label={
                chapter.status === 'published'
                  ? dictionary.published
                  : dictionary['writing in progress']
              }
              size="small"
            />
          )}
        </Stack>
        <CardContent sx={{ flex: 1 }}>
          <Typography
            variant="subtitle1"
            component="h2"
            fontWeight="bold"
            sx={{
              display: '-webkit-box',
              WebkitLineClamp: 2,
              WebkitBoxOrient: 'vertical',
              overflow: 'hidden'
            }}
          >
            {journeyHeadline(journey, dictionary['untitled chapter']) ??
              dictionary['untitled journey']}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {formatLocal(
              journey.started_at ?? journey.created_at,
              DATE_OPTIONS
            )}
          </Typography>
          {journey.map?.name && (
            <Typography variant="body2" color="text.secondary" noWrap>
              {journey.map.name}
            </Typography>
          )}
          <Typography variant="caption" color="text.secondary">
            {started
              ? dictionary['checkins count'].replace(
                  '{count}',
                  String(journey.checkins_count)
                )
              : dictionary['milestones count'].replace(
                  '{count}',
                  String(journey.milestones_count)
                )}
          </Typography>
        </CardContent>
      </CardActionArea>

      <CardActions disableSpacing sx={{ gap: 1 }}>
        {writable && (
          <Button
            variant="contained"
            color="secondary"
            disableElevation
            startIcon={<HistoryEdu />}
            loading={writing}
            disabled={writeDisabled}
            onClick={() => onWrite(journey)}
          >
            {dictionary['record as chapter']}
          </Button>
        )}
        {chapter?.status === 'draft' && (
          <Button
            color="secondary"
            startIcon={<HistoryEdu />}
            component={Link}
            href={`/${lang}/chapters/${chapter.id}/edit`}
          >
            {dictionary['continue writing']}
          </Button>
        )}
        <IconButton
          aria-label={dictionary.more}
          onClick={(event) => onMore(event, journey)}
          sx={{ ml: 'auto' }}
        >
          <MoreVert />
        </IconButton>
      </CardActions>
    </Card>
  );
}
