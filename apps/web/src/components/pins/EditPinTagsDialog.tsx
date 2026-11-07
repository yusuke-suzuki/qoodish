import { enqueueSnackbar } from 'notistack';
import { type FormEvent, useState, useTransition } from 'react';
import type { AppMap, Pin, PinProperty } from '../../../types/index.ts';
import { updatePinPropertyOptions } from '../../actions/pins.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import { offeredOptionIds } from '../../utils/pinPropertyOptions.ts';
import AppDialog from '../common/AppDialog.tsx';
import PinPropertyOptionsField from './PinPropertyOptionsField.tsx';

type Props = {
  open: boolean;
  onClose: () => void;
  onSaved: () => void;
  currentPin: Pin | null;
  map: AppMap | null;
  pinProperties: PinProperty[];
};

export default function EditPinTagsDialog({
  open,
  onClose,
  onSaved,
  currentPin,
  map,
  pinProperties
}: Props) {
  const dictionary = useDictionary();

  const [optionIds, setOptionIds] = useState<number[]>([]);
  const [isPending, startTransition] = useTransition();

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!currentPin) {
      return;
    }

    startTransition(async () => {
      const result = await updatePinPropertyOptions(
        currentPin.map.id,
        currentPin.id,
        offeredOptionIds(pinProperties, optionIds)
      );

      if (result.success) {
        enqueueSnackbar(dictionary['edit pin tags success'], {
          variant: 'success'
        });
        onClose();
        onSaved();
        return;
      }

      enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
        variant: 'error'
      });
    });
  };

  return (
    <AppDialog
      open={open}
      onClose={onClose}
      title={dictionary['edit pin tags']}
      fullScreenOnMobile
      cancelLabel={dictionary.cancel}
      disableClose={isPending}
      onSubmit={handleSubmit}
      onEnter={() =>
        setOptionIds(
          offeredOptionIds(pinProperties, currentPin?.property_option_ids ?? [])
        )
      }
      confirmAction={{
        label: dictionary.save,
        type: 'submit',
        disabled: !currentPin,
        loading: isPending
      }}
    >
      <PinPropertyOptionsField
        map={map}
        pinProperties={pinProperties}
        value={optionIds}
        disabled={isPending}
        onChange={setOptionIds}
      />
    </AppDialog>
  );
}
