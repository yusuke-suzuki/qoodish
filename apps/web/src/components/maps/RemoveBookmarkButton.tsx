import { Bookmark } from '@mui/icons-material';
import { enqueueSnackbar } from 'notistack';
import { useContext, useState, useTransition } from 'react';
import type { AppMap, Profile } from '../../../types/index.ts';
import { removeBookmark } from '../../actions/mapBookmarks.ts';
import AuthContext from '../../context/AuthContext.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import ActionButton from '../common/ActionButton.tsx';

type Props = {
  map: AppMap | null;
  currentProfile: Profile | null;
  onSaved: () => void;
};

function RemoveBookmarkButton({ map, currentProfile, onSaved }: Props) {
  const { authenticated, setSignInRequired } = useContext(AuthContext);
  const dictionary = useDictionary();

  const [bookmarking, setBookmarking] = useState(map?.bookmarking ?? false);
  const [isPending, startTransition] = useTransition();

  const isAuthor = currentProfile?.id === map?.author.id;

  const handleClick = () => {
    if (!map) {
      return;
    }

    if (!authenticated) {
      setSignInRequired(true);
      return;
    }

    setBookmarking(false);

    startTransition(async () => {
      try {
        const result = await removeBookmark(map.id);

        if (result.success) {
          onSaved();

          enqueueSnackbar(dictionary['unfollow map success'], {
            variant: 'success'
          });
        } else {
          setBookmarking(true);
          enqueueSnackbar(result.error, { variant: 'error' });
        }
      } catch (_error) {
        setBookmarking(true);
        enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
      }
    });
  };

  return (
    <ActionButton
      icon={<Bookmark />}
      label={dictionary.bookmarked}
      active
      loading={isPending}
      disabled={!map || !bookmarking || isAuthor}
      onClick={handleClick}
    />
  );
}

export default RemoveBookmarkButton;
