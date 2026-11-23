'use client';

import { Favorite, FavoriteBorder } from '@mui/icons-material';
import { Box, Checkbox, Tooltip } from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import { type ChangeEvent, useContext, useState, useTransition } from 'react';
import type { Chapter } from '../../../types/index.ts';
import { likeChapter, unlikeChapter } from '../../actions/chapterLikes.ts';
import AuthContext from '../../context/AuthContext.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import ShareButton from '../common/ShareButton.tsx';

type Props = {
  chapter: Chapter;
};

function ChapterActions({ chapter }: Props) {
  const { authenticated, setSignInRequired } = useContext(AuthContext);
  const dictionary = useDictionary();

  const [liked, setLiked] = useState(chapter.liked);
  const [isPending, startTransition] = useTransition();

  const handleLikeChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (!authenticated) {
      setSignInRequired(true);
      return;
    }

    const next = event.target.checked;
    setLiked(next);

    startTransition(async () => {
      try {
        const result = next
          ? await likeChapter(chapter.id)
          : await unlikeChapter(chapter.id);

        if (result.success) {
          enqueueSnackbar(dictionary[next ? 'liked!' : 'unliked'], {
            variant: 'info'
          });
        } else {
          setLiked(!next);
          enqueueSnackbar(result.error, { variant: 'error' });
        }
      } catch (_error) {
        setLiked(!next);
        enqueueSnackbar(dictionary['an error occurred'], {
          variant: 'error'
        });
      }
    });
  };

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
      <Tooltip
        title={liked ? dictionary['button unlike'] : dictionary['button like']}
      >
        <Checkbox
          icon={<FavoriteBorder />}
          checkedIcon={<Favorite />}
          checked={liked}
          disabled={isPending}
          onChange={handleLikeChange}
          slotProps={{
            input: {
              'aria-label': liked
                ? dictionary['button unlike']
                : dictionary['button like']
            }
          }}
        />
      </Tooltip>

      <ShareButton title={chapter.title} path={`/chapters/${chapter.id}`} />
    </Box>
  );
}

export default ChapterActions;
