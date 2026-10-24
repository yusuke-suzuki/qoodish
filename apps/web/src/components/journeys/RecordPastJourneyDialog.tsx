'use client';

import {
  AddPhotoAlternate,
  KeyboardArrowLeft,
  KeyboardArrowRight,
  Map as MapIcon
} from '@mui/icons-material';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Chip,
  CircularProgress,
  LinearProgress,
  Stack,
  Typography
} from '@mui/material';
import { useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { type ChangeEvent, useEffect, useId, useRef, useState } from 'react';
import type { CountedMap, Pin } from '../../../types/index.ts';
import { addCheckin, recordPastJourney } from '../../actions/journeys.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalePath from '../../hooks/useLocalePath.ts';
import {
  CHECKIN_IMAGE_LIMIT,
  type CheckinDraft,
  CLOCK_SKEW_MS,
  draftCheckin,
  groupPhotos,
  journeyPeriod,
  toggledSelection,
  withPin
} from '../../utils/checkinDrafts.ts';
import { fetchMapPins, fetchRelatedMaps } from '../../utils/maps.ts';
import readCapturedAt from '../../utils/readCapturedAt.ts';
import {
  splitOversizedImages,
  uploadImageWhenAllowed
} from '../../utils/uploadImage.ts';
import AppDialog from '../common/AppDialog.tsx';
import LoadingStatus from '../common/LoadingStatus.tsx';
import CheckinDraftCard, { type PreviewPhoto } from './CheckinDraftCard.tsx';
import MapPicker from './MapPicker.tsx';
import PinPickerDialog from './PinPickerDialog.tsx';

type Phase = 'choosing' | 'reading' | 'reviewing' | 'recording' | 'recorded';

type Progress = {
  done: number;
  total: number;
};

type Props = {
  open: boolean;
  onClose: () => void;
};

const NO_PROGRESS: Progress = { done: 0, total: 0 };

const LAST_STEP = 2;

function Loading() {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
      <LoadingStatus loading />
      <CircularProgress color="secondary" />
    </Box>
  );
}

export default function RecordPastJourneyDialog({ open, onClose }: Props) {
  const dictionary = useDictionary();
  const localePath = useLocalePath();
  const router = useRouter();
  const inputId = useId();

  const [maps, setMaps] = useState<CountedMap[] | null>(null);
  const [step, setStep] = useState(0);
  const [map, setMap] = useState<CountedMap | null>(null);
  const [pins, setPins] = useState<Pin[] | null>(null);
  const [phase, setPhase] = useState<Phase>('choosing');
  const [photos, setPhotos] = useState<PreviewPhoto[]>([]);
  const [drafts, setDrafts] = useState<CheckinDraft<PreviewPhoto>[]>([]);
  const [pickingIndex, setPickingIndex] = useState<number | null>(null);
  const [progress, setProgress] = useState<Progress>(NO_PROGRESS);
  const [journeyId, setJourneyId] = useState<number | null>(null);
  const [unrecorded, setUnrecorded] = useState(0);
  const mountedRef = useRef(false);
  const requestedMapIdRef = useRef<number | null>(null);

  useEffect(() => {
    mountedRef.current = true;

    return () => {
      mountedRef.current = false;
    };
  }, []);

  useEffect(
    () => () => {
      for (const photo of photos) {
        URL.revokeObjectURL(photo.previewUrl);
      }
    },
    [photos]
  );

  useEffect(() => {
    if (phase !== 'recording') {
      return;
    }

    const warn = (event: BeforeUnloadEvent) => event.preventDefault();
    window.addEventListener('beforeunload', warn);

    return () => window.removeEventListener('beforeunload', warn);
  }, [phase]);

  const pinsById = new Map((pins ?? []).map((pin) => [pin.id, pin]));

  const chosenPinIds = new Set(
    drafts
      .filter((_, index) => index !== pickingIndex)
      .map((draft) => draft.pinId)
  );

  const recordable =
    drafts.length > 0 && drafts.every((draft) => draft.pinId !== null);

  const handleEnter = async () => {
    try {
      const fetched = await fetchRelatedMaps();

      if (mountedRef.current) {
        setMaps(fetched);
      }
    } catch {
      enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
      onClose();
    }
  };

  const handleSelectMap = async (selected: CountedMap) => {
    const stillRequested = () =>
      mountedRef.current && requestedMapIdRef.current === selected.id;

    if (selected.id === requestedMapIdRef.current) {
      return;
    }

    requestedMapIdRef.current = selected.id;
    setMap(selected);
    setPins(null);
    setPhotos([]);
    setDrafts([]);
    setPhase('choosing');

    try {
      const fetched = await fetchMapPins(selected.id);

      if (stillRequested()) {
        setPins(fetched);
      }
    } catch {
      if (stillRequested()) {
        enqueueSnackbar(dictionary['an error occurred'], {
          variant: 'error'
        });
        requestedMapIdRef.current = null;
        setMap(null);
      }
    }
  };

  const handleExited = () => {
    requestedMapIdRef.current = null;
    setStep(0);
    setMaps(null);
    setMap(null);
    setPins(null);
    setPhase('choosing');
    setPhotos([]);
    setDrafts([]);
    setPickingIndex(null);
    setProgress(NO_PROGRESS);
    setJourneyId(null);
    setUnrecorded(0);
  };

  const handleClose = () => {
    if (phase === 'recorded') {
      router.refresh();
    }

    onClose();
  };

  const handleFilesChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const { accepted, oversized } = splitOversizedImages(
      Array.from(event.target.files ?? [])
    );
    event.target.value = '';

    if (oversized.length > 0) {
      enqueueSnackbar(dictionary['image too large'], { variant: 'error' });
    }

    if (accepted.length < 1) {
      return;
    }

    setPhase('reading');

    const read = await Promise.all(
      accepted.map(async (file) => ({
        file,
        capturedAt: await readCapturedAt(file)
      }))
    );

    const latest = Date.now() + CLOCK_SKEW_MS;
    const dated = read.filter(
      (entry): entry is { file: File; capturedAt: number } =>
        entry.capturedAt !== null && entry.capturedAt <= latest
    );
    const undated = read.length - dated.length;

    if (dated.length < 1) {
      enqueueSnackbar(dictionary['no photos with capture time'], {
        variant: 'error'
      });
      setPhase(drafts.length > 0 ? 'reviewing' : 'choosing');
      return;
    }

    const chosen: PreviewPhoto[] = dated.map(({ file, capturedAt }) => ({
      key: crypto.randomUUID(),
      file,
      capturedAt,
      previewUrl: URL.createObjectURL(file)
    }));

    if (undated > 0) {
      enqueueSnackbar(
        dictionary['photos without capture time'].replace(
          '{count}',
          String(undated)
        )
      );
    }

    setPhotos(chosen);
    setDrafts(groupPhotos(chosen).map(draftCheckin));
    setPhase('reviewing');
  };

  const updateDraft = (
    index: number,
    update: (draft: CheckinDraft<PreviewPhoto>) => CheckinDraft<PreviewPhoto>
  ) => {
    setDrafts((current) =>
      current.map((draft, i) => (i === index ? update(draft) : draft))
    );
  };

  const handleTogglePhoto = (index: number, photoKey: string) => {
    const selected = toggledSelection(drafts[index], photoKey);

    if (!selected) {
      enqueueSnackbar(
        dictionary['checkin photo limit'].replace(
          '{limit}',
          String(CHECKIN_IMAGE_LIMIT)
        )
      );
      return;
    }

    updateDraft(index, (draft) => ({ ...draft, selected }));
  };

  const handleRemoveDraft = (index: number) => {
    setDrafts((current) => current.toSpliced(index, 1));
  };

  const handleSelectPin = (pin: Pin) => {
    if (pickingIndex !== null) {
      setDrafts((current) => withPin(current, pickingIndex, pin.id));
    }

    setPickingIndex(null);
  };

  const handleOpenJourney = () => {
    if (journeyId !== null) {
      router.push(localePath(`/journeys/${journeyId}`));
    }

    onClose();
  };

  const handleRecord = async () => {
    if (!map) {
      return;
    }

    const targets = drafts.flatMap(({ pinId, ...draft }) =>
      pinId === null ? [] : [{ ...draft, pinId }]
    );
    const onPage = () => mountedRef.current;

    setPhase('recording');
    setProgress({ done: 0, total: targets.length });

    const period = journeyPeriod(
      targets.flatMap((draft) => draft.photos.map((photo) => photo.capturedAt))
    );

    try {
      const { success, data, error } = await recordPastJourney(
        map.id,
        period.startedAt,
        period.finishedAt
      );

      if (!success || !data) {
        enqueueSnackbar(error ?? dictionary['an error occurred'], {
          variant: 'error'
        });
        setPhase('reviewing');
        return;
      }

      let failures = 0;
      let unattached = 0;

      for (const [index, draft] of targets.entries()) {
        try {
          const uploads = await Promise.allSettled(
            draft.photos
              .filter((photo) => draft.selected.includes(photo.key))
              .map((photo) => uploadImageWhenAllowed(photo.file))
          );
          const imageIds = uploads.flatMap((upload) =>
            upload.status === 'fulfilled' ? [upload.value.id] : []
          );
          unattached += uploads.length - imageIds.length;

          const result = await addCheckin(
            data.id,
            draft.pinId,
            new Date(draft.photos[0].capturedAt).toISOString(),
            imageIds
          );

          if (!result.success) {
            failures += 1;
            unattached += imageIds.length;
          }
        } catch {
          failures += 1;
        }

        if (onPage()) {
          setProgress({ done: index + 1, total: targets.length });
        }
      }

      if (unattached > 0) {
        enqueueSnackbar(
          dictionary['photos not attached'].replace(
            '{count}',
            String(unattached)
          ),
          { variant: 'warning' }
        );
      }

      if (!onPage()) {
        return;
      }

      if (failures < 1) {
        router.push(localePath(`/journeys/${data.id}`));
        onClose();
        return;
      }

      setJourneyId(data.id);
      setUnrecorded(failures);
      setPhase('recorded');
    } catch {
      enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });

      if (onPage()) {
        setPhase('reviewing');
      }
    }
  };

  const busy = phase === 'reading' || phase === 'recording';
  const recorded = phase === 'recorded';

  const canProceed = [
    map !== null && pins !== null && pins.length > 0,
    drafts.length > 0,
    recordable
  ][step];

  // Count a step as done once its input is complete, so the bar starts empty
  // and fills as the user makes progress rather than on entering a step.
  const completion = ((step + (canProceed ? 1 : 0)) / (LAST_STEP + 1)) * 100;

  const handleNext = () => {
    if (step < LAST_STEP) {
      setStep(step + 1);
      return;
    }

    handleRecord();
  };

  const handleBack = () => {
    if (step > 0) {
      setStep(step - 1);
      return;
    }

    handleClose();
  };

  const navigation = recorded ? undefined : (
    <Stack direction="row" spacing={1} sx={{ width: '100%' }}>
      <Button
        fullWidth
        size="large"
        variant="outlined"
        color="inherit"
        disabled={busy}
        startIcon={step > 0 ? <KeyboardArrowLeft /> : undefined}
        onClick={handleBack}
      >
        {step > 0 ? dictionary.back : dictionary.cancel}
      </Button>
      <Button
        fullWidth
        size="large"
        variant="contained"
        color="secondary"
        disableElevation
        disabled={busy || !canProceed}
        loading={phase === 'recording'}
        endIcon={step < LAST_STEP ? <KeyboardArrowRight /> : undefined}
        onClick={handleNext}
      >
        {step < LAST_STEP
          ? dictionary.next
          : dictionary['record past journey confirm']}
      </Button>
    </Stack>
  );

  const selectedPhotoCount = drafts.reduce(
    (count, draft) => count + draft.selected.length,
    0
  );

  const draftCards = (withPins: boolean) =>
    drafts.map((draft, index) => (
      <CheckinDraftCard
        key={draft.photos[0].key}
        draft={draft}
        pin={draft.pinId === null ? null : (pinsById.get(draft.pinId) ?? null)}
        disabled={busy}
        onTogglePhoto={(photoKey) => handleTogglePhoto(index, photoKey)}
        onRemove={() => handleRemoveDraft(index)}
        onChoosePin={withPins ? () => setPickingIndex(index) : undefined}
      />
    ));

  const mapChip = map && (
    <Box>
      <Chip
        avatar={
          <Avatar src={map.image?.avatar} alt={map.name}>
            <MapIcon fontSize="small" />
          </Avatar>
        }
        label={map.name}
      />
    </Box>
  );

  return (
    <AppDialog
      open={open}
      onClose={handleClose}
      title={dictionary['record past journey']}
      fullScreenOnMobile
      dividers
      disableQuickDismiss
      disableClose={busy}
      confirmAction={
        recorded
          ? { label: dictionary['open journey'], onClick: handleOpenJourney }
          : undefined
      }
      cancelLabel={recorded ? dictionary.close : undefined}
      actions={navigation}
      progress={recorded ? undefined : completion}
      onEnter={handleEnter}
      onExited={handleExited}
    >
      <input
        accept="image/*"
        multiple
        hidden
        id={inputId}
        type="file"
        onChange={handleFilesChange}
      />

      {recorded ? (
        <Alert severity="warning">
          {dictionary['checkins not recorded'].replace(
            '{count}',
            String(unrecorded)
          )}
        </Alert>
      ) : step === 0 ? (
        maps === null ? (
          <Loading />
        ) : (
          <Stack spacing={2}>
            {maps.length > 0 && (
              <Typography variant="body2">
                {dictionary['which map did you travel with']}
              </Typography>
            )}
            <MapPicker
              maps={maps}
              selectedId={map?.id ?? null}
              onSelect={handleSelectMap}
            />
            {map && pins === null && <Loading />}
          </Stack>
        )
      ) : step === 1 ? (
        <Stack spacing={2}>
          {mapChip}
          <Box>
            <Typography variant="body2">
              {dictionary['choose journey photos']}
            </Typography>
            <Typography variant="body2">
              {dictionary['checkins from capture times']}
            </Typography>
          </Box>
          <Button
            component="label"
            htmlFor={inputId}
            variant={drafts.length > 0 ? 'outlined' : 'contained'}
            color="secondary"
            disableElevation
            startIcon={<AddPhotoAlternate />}
            loading={phase === 'reading'}
          >
            {drafts.length > 0
              ? dictionary['choose other photos']
              : dictionary['choose photos']}
          </Button>
          {drafts.length > 0 && phase !== 'reading' && (
            <>
              <Typography variant="body2" color="text.secondary">
                {dictionary['photos to checkins']
                  .replace('{photos}', String(selectedPhotoCount))
                  .replace('{checkins}', String(drafts.length))}
              </Typography>
              {draftCards(false)}
            </>
          )}
        </Stack>
      ) : (
        <Stack spacing={2}>
          {mapChip}
          <Typography variant="body2">
            {dictionary['choose checkin pins']}
          </Typography>

          {draftCards(true)}

          {phase === 'recording' && (
            <Box>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                {dictionary['recording checkins']
                  .replace('{done}', String(progress.done))
                  .replace('{total}', String(progress.total))}
              </Typography>
              <LinearProgress
                variant="determinate"
                color="secondary"
                value={
                  progress.total > 0
                    ? (progress.done / progress.total) * 100
                    : 0
                }
              />
            </Box>
          )}
        </Stack>
      )}

      <PinPickerDialog
        open={pickingIndex !== null}
        onClose={() => setPickingIndex(null)}
        onSelect={handleSelectPin}
        pins={pins ?? []}
        usedPinIds={chosenPinIds}
      />
    </AppDialog>
  );
}
