'use client';

import { DeleteOutline } from '@mui/icons-material';
import {
  Box,
  IconButton,
  ListItem,
  ListItemIcon,
  Stack,
  Tooltip
} from '@mui/material';
import { useState } from 'react';
import type { PinProperty, PinPropertyOption } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';
import { tagPalette } from '../common/TagChip.tsx';
import NameEditField from './NameEditField.tsx';
import PinPropertyAppearanceDialog from './PinPropertyAppearanceDialog.tsx';
import type { PinPropertyAppearance } from './PinPropertyAppearanceFields.tsx';
import PinPropertyOptionsInput from './PinPropertyOptionsInput.tsx';
import PinPropertyTypeIcon from './PinPropertyTypeIcon.tsx';
import RenameOptionDialog from './RenameOptionDialog.tsx';

type Props = {
  property: PinProperty;
  onRename: (name: string) => Promise<boolean>;
  onChangeAppearance: (appearance: PinPropertyAppearance) => Promise<boolean>;
  onDelete: () => void;
  onCreateOption: (name: string) => Promise<boolean>;
  onRenameOption: (option: PinPropertyOption, name: string) => Promise<boolean>;
  onDeleteOption: (option: PinPropertyOption) => void;
};

export default function PinPropertyListItem({
  property,
  onRename,
  onChangeAppearance,
  onDelete,
  onCreateOption,
  onRenameOption,
  onDeleteOption
}: Props) {
  const dictionary = useDictionary();

  const [appearanceOpen, setAppearanceOpen] = useState(false);
  const [renamingOption, setRenamingOption] =
    useState<PinPropertyOption | null>(null);

  const tagColor = property.color;

  const typeLabel = property.multiple
    ? dictionary['multi select']
    : dictionary['single select'];

  return (
    <ListItem sx={{ display: 'block', px: 0, py: 2 }}>
      <Stack direction="row" alignItems="center">
        <ListItemIcon>
          <IconButton
            edge="start"
            aria-label={dictionary['pin property appearance']}
            title={dictionary['pin property appearance']}
            onClick={() => setAppearanceOpen(true)}
            sx={
              tagColor
                ? (theme) => {
                    const palette = tagPalette(theme, tagColor);

                    return {
                      bgcolor: palette.main,
                      color: palette.contrastText,
                      '&:hover, &.Mui-focusVisible': { bgcolor: palette.dark }
                    };
                  }
                : undefined
            }
          >
            <PinPropertyIcon icon={property.icon} />
          </IconButton>
        </ListItemIcon>
        <NameEditField
          label={dictionary['pin property name']}
          defaultValue={property.name}
          onSave={onRename}
        />
        <Tooltip title={typeLabel}>
          <Box sx={{ display: 'flex', ml: 1, color: 'action.active' }}>
            <PinPropertyTypeIcon multiple={property.multiple} />
          </Box>
        </Tooltip>
        <IconButton
          edge="end"
          aria-label={dictionary.delete}
          title={dictionary.delete}
          onClick={onDelete}
          sx={{ ml: 1 }}
        >
          <DeleteOutline />
        </IconButton>
      </Stack>

      <Box sx={{ mt: 2, pl: 7 }}>
        <PinPropertyOptionsInput
          options={property.options}
          onCreate={onCreateOption}
          onRename={setRenamingOption}
          onDelete={onDeleteOption}
        />
      </Box>

      <PinPropertyAppearanceDialog
        property={property}
        open={appearanceOpen}
        onClose={() => setAppearanceOpen(false)}
        onSave={onChangeAppearance}
      />

      <RenameOptionDialog
        option={renamingOption}
        onClose={() => setRenamingOption(null)}
        onRename={onRenameOption}
      />
    </ListItem>
  );
}
