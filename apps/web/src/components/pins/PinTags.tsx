'use client';

import { enqueueSnackbar } from 'notistack';
import { useState } from 'react';
import type { AppMap, Pin, PinProperty } from '../../../types/index.ts';
import { updatePinPropertyOptions } from '../../actions/pins.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import {
  offeredOptionIds,
  toggleOption
} from '../../utils/pinPropertyOptions.ts';
import PinPropertyValues from '../common/PinPropertyValues.tsx';
import PinTagEditor from './PinTagEditor.tsx';

type StoredTags = { ids: number[]; updatedAt: string };

function storedTags(
  pin: Pick<Pin, 'property_option_ids' | 'updated_at'>
): StoredTags {
  return { ids: pin.property_option_ids, updatedAt: pin.updated_at };
}

function newer(known: StoredTags, incoming: StoredTags): StoredTags {
  return incoming.updatedAt >= known.updatedAt ? incoming : known;
}

type Props = {
  pin: Pin;
  map: AppMap | null;
  pinProperties: PinProperty[];
  onSaved: () => void;
};

export default function PinTags({ pin, map, pinProperties, onSaved }: Props) {
  const dictionary = useDictionary();

  const [stored, setStored] = useState(storedTags(pin));
  const [shownPin, setShownPin] = useState(pin);
  const [pendingIds, setPendingIds] = useState<number[] | null>(null);

  if (pin !== shownPin) {
    setShownPin(pin);
    setStored(newer(stored, storedTags(pin)));
  }

  const optionIds = pendingIds ?? stored.ids;
  const saving = pendingIds !== null;

  const toggle = async (property: PinProperty, optionId: number) => {
    const next = toggleOption(optionIds, property, optionId);

    setPendingIds(next);

    const result = await updatePinPropertyOptions(
      pin.map.id,
      pin.id,
      offeredOptionIds(pinProperties, next)
    ).catch(() => ({ success: false, data: undefined, error: undefined }));

    setPendingIds(null);

    if (result.success && result.data) {
      const saved = storedTags(result.data);
      setStored((current) => newer(current, saved));
      onSaved();
      return;
    }

    enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
      variant: 'error'
    });
  };

  if (!map?.editable) {
    return (
      <PinPropertyValues optionIds={optionIds} pinProperties={pinProperties} />
    );
  }

  return (
    <PinTagEditor
      map={map}
      pinProperties={pinProperties}
      value={optionIds}
      disabled={saving}
      onToggle={toggle}
    />
  );
}
