'use client';

import { type FormEvent, useState, useTransition } from 'react';
import type { PinProperty } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import AppDialog from '../common/AppDialog.tsx';
import PinPropertyAppearanceFields, {
  appearanceInvalid,
  type PinPropertyAppearance
} from './PinPropertyAppearanceFields.tsx';

type Props = {
  property: PinProperty;
  open: boolean;
  onClose: () => void;
  onSave: (appearance: PinPropertyAppearance) => Promise<boolean>;
};

export default function PinPropertyAppearanceDialog({
  property,
  open,
  onClose,
  onSave
}: Props) {
  const dictionary = useDictionary();

  const [appearance, setAppearance] = useState<PinPropertyAppearance>({
    icon: property.icon,
    color: property.color
  });
  const [isPending, startTransition] = useTransition();

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    startTransition(async () => {
      if (await onSave(appearance)) {
        onClose();
      }
    });
  };

  return (
    <AppDialog
      open={open}
      onClose={onClose}
      title={dictionary['pin property appearance']}
      cancelLabel={dictionary.cancel}
      disableClose={isPending}
      onSubmit={handleSubmit}
      onEnter={() =>
        setAppearance({ icon: property.icon, color: property.color })
      }
      confirmAction={{
        label: dictionary.save,
        type: 'submit',
        disabled: appearanceInvalid(appearance),
        loading: isPending
      }}
    >
      <PinPropertyAppearanceFields
        name={property.name}
        value={appearance}
        disabled={isPending}
        onChange={setAppearance}
      />
    </AppDialog>
  );
}
