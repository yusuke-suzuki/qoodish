'use client';

import { Box, IconButton, Tab, Tabs } from '@mui/material';
import { type ReactNode, useId, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';
import {
  EMOJI_CATEGORIES,
  type EmojiCategoryId,
  emojiCategoryOf
} from '../../utils/emojiCategories.ts';

export const EMOJI_CELL_SIZE = 40;

const COLUMNS = 6;

type Props = {
  value?: string | null;
  leading?: ReactNode;
  onSelect: (emoji: string) => void;
};

export default function EmojiPicker({
  value = null,
  leading,
  onSelect
}: Props) {
  const dictionary = useDictionary();
  const id = useId();

  const [category, setCategory] = useState<EmojiCategoryId>(
    () => emojiCategoryOf(value) ?? EMOJI_CATEGORIES[0].id
  );

  const emoji = EMOJI_CATEGORIES.find(
    (candidate) => candidate.id === category
  )?.emoji;

  return (
    <Box sx={{ width: 296, maxWidth: '100%' }}>
      <Tabs
        value={category}
        onChange={(_, next: EmojiCategoryId) => setCategory(next)}
        variant="fullWidth"
        sx={{ borderBottom: 1, borderColor: 'divider' }}
      >
        {EMOJI_CATEGORIES.map((candidate) => {
          const label = dictionary[`emoji category ${candidate.id}`];

          return (
            <Tab
              key={candidate.id}
              value={candidate.id}
              id={`${id}-tab-${candidate.id}`}
              aria-controls={`${id}-panel`}
              aria-label={label}
              title={label}
              label={candidate.emoji[0]}
              sx={{ minWidth: 0, px: 0, fontSize: 20 }}
            />
          );
        })}
      </Tabs>
      <Box
        id={`${id}-panel`}
        role="tabpanel"
        aria-labelledby={`${id}-tab-${category}`}
        sx={{
          display: 'grid',
          gridTemplateColumns: `repeat(${COLUMNS}, 1fr)`,
          justifyItems: 'center',
          gap: 0.5,
          p: 1.5
        }}
      >
        {leading}
        {emoji?.map((candidate) => (
          <IconButton
            key={candidate}
            aria-label={candidate}
            aria-pressed={candidate === value}
            onClick={() => onSelect(candidate)}
            sx={{
              width: EMOJI_CELL_SIZE,
              height: EMOJI_CELL_SIZE,
              fontSize: 22,
              lineHeight: 1,
              bgcolor: candidate === value ? 'action.selected' : undefined
            }}
          >
            {candidate}
          </IconButton>
        ))}
      </Box>
    </Box>
  );
}
