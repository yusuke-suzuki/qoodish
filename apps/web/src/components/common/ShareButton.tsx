'use client';

import { Share } from '@mui/icons-material';
import { IconButton, Tooltip } from '@mui/material';
import useDictionary from '../../hooks/useDictionary.ts';
import useLocalePath from '../../hooks/useLocalePath.ts';
import useShare from '../../hooks/useShare.ts';
import { SITE_ORIGIN } from '../../utils/metadata.ts';
import ActionButton from './ActionButton.tsx';

type Props = {
  title: string;
  path: string;
  labeled?: boolean;
};

export default function ShareButton({ title, path, labeled }: Props) {
  const dictionary = useDictionary();
  const localePath = useLocalePath();
  const share = useShare();

  const handleClick = () => {
    share({ title, url: `${SITE_ORIGIN}${localePath(path)}` });
  };

  if (labeled) {
    return (
      <ActionButton
        icon={<Share />}
        label={dictionary.share}
        onClick={handleClick}
      />
    );
  }

  return (
    <Tooltip title={dictionary.share}>
      <IconButton onClick={handleClick} aria-label={dictionary.share}>
        <Share />
      </IconButton>
    </Tooltip>
  );
}
