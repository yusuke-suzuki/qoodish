import { BookmarkBorder } from '@mui/icons-material';
import { enqueueSnackbar } from 'notistack';
import { useContext, useState, useTransition } from 'react';
import type { AppMap } from '../../../types/index.ts';
import { bookmarkMap } from '../../actions/mapBookmarks.ts';
import AuthContext from '../../context/AuthContext.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import ActionButton from '../common/ActionButton.tsx';

type Props = {
  map: AppMap | null;
  onSaved: () => void;
};

function BookmarkButton({ map, onSaved }: Props) {
  const { authenticated, setSignInRequired } = useContext(AuthContext);
  const dictionary = useDictionary();

  const [bookmarking, setBookmarking] = useState(map?.bookmarking ?? false);
  const [isPending, startTransition] = useTransition();

  const handleClick = () => {
    if (!map) {
      return;
    }

    if (!authenticated) {
      setSignInRequired(true);
      return;
    }

    setBookmarking(true);

    startTransition(async () => {
      try {
        const result = await bookmarkMap(map.id);

        if (result.success) {
          onSaved();

          enqueueSnackbar(dictionary['follow map success'], {
            variant: 'success'
          });
        } else {
          setBookmarking(false);
          enqueueSnackbar(result.error, { variant: 'error' });
        }
      } catch (_error) {
        setBookmarking(false);
        enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
      }
    });
  };

  return (
    <ActionButton
      icon={<BookmarkBorder />}
      label={dictionary.follow}
      active={false}
      loading={isPending}
      disabled={!map || bookmarking}
      onClick={handleClick}
    />
  );
}

export default BookmarkButton;
