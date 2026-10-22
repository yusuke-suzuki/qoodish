import { enqueueSnackbar } from 'notistack';
import { deleteAccount } from '../../actions/users.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import ConfirmDeleteDialog from '../common/ConfirmDeleteDialog.tsx';
import ProfileBoundary from '../common/ProfileBoundary.tsx';

type Props = {
  open: boolean;
  onClose: () => void;
  onDeleted: () => void;
};

type ContentProps = Props & {
  userId?: number;
};

function DeleteAccountDialogContent({
  open,
  onClose,
  onDeleted,
  userId
}: ContentProps) {
  const dictionary = useDictionary();

  const handleConfirm = async () => {
    try {
      const result = await deleteAccount(userId);

      if (result.success) {
        enqueueSnackbar(dictionary['delete account success'], {
          variant: 'success'
        });

        onClose();
        onDeleted();
        return;
      }

      enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
        variant: 'error'
      });
    } catch (_error) {
      enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
    }
  };

  return (
    <ConfirmDeleteDialog
      open={open}
      title={dictionary['sure to delete account']}
      description={dictionary['delete account detail']}
      onClose={onClose}
      onConfirm={handleConfirm}
    />
  );
}

export default function DeleteAccountDialog(props: Props) {
  return (
    <ProfileBoundary>
      {(profile) => (
        <DeleteAccountDialogContent {...props} userId={profile?.id} />
      )}
    </ProfileBoundary>
  );
}
