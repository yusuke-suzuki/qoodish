'use client';

import { Close, DeleteOutline } from '@mui/icons-material';
import {
  Box,
  IconButton,
  InputAdornment,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListSubheader,
  Stack,
  TextField
} from '@mui/material';
import { type FocusEvent, type FormEvent, useRef } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';
import type { PinPropertyAppearance } from '../../utils/pinPropertyOptions.ts';
import PinPropertyIcon from '../common/PinPropertyIcon.tsx';
import PinPropertyColorPicker from './PinPropertyColorPicker.tsx';
import PinPropertyIconPicker from './PinPropertyIconPicker.tsx';
import PinPropertyOptionAddField from './PinPropertyOptionAddField.tsx';
import PinPropertyTypeIcon from './PinPropertyTypeIcon.tsx';

export const NAME_LIMIT = 30;

export type PinPropertyDraft = PinPropertyAppearance & {
  name: string;
  multiple: boolean;
  options: string[];
  optionInput: string;
};

export const EMPTY_DRAFT: PinPropertyDraft = {
  name: '',
  multiple: false,
  icon: null,
  color: null,
  options: [],
  optionInput: ''
};

function uniqueNames(names: string[]): string[] {
  return Array.from(
    new Set(names.map((name) => name.trim()).filter((name) => name))
  );
}

export function draftOptionNames(draft: PinPropertyDraft): string[] {
  return uniqueNames([...draft.options, draft.optionInput]);
}

export function draftCommittable(draft: PinPropertyDraft): boolean {
  const name = draft.name.trim();

  return (
    name !== '' &&
    name.length <= NAME_LIMIT &&
    draftOptionNames(draft).every((option) => option.length <= NAME_LIMIT)
  );
}

type Props = {
  draft: PinPropertyDraft;
  disabled?: boolean;
  onChange: (update: (draft: PinPropertyDraft) => PinPropertyDraft) => void;
  onCommit: () => void;
  onCancel: () => void;
};

export default function NewPinPropertyListItem({
  draft,
  disabled,
  onChange,
  onCommit,
  onCancel
}: Props) {
  const dictionary = useDictionary();
  const itemRef = useRef<HTMLLIElement>(null);

  const tooLong = draft.name.trim().length > NAME_LIMIT;
  const typeLabel = draft.multiple
    ? dictionary['multi select']
    : dictionary['single select'];

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onCommit();
  };

  const handleBlur = (event: FocusEvent<HTMLLIElement>) => {
    const next = event.relatedTarget;

    if (
      next instanceof Element &&
      !itemRef.current?.contains(next) &&
      !next.closest('.MuiPopover-root')
    ) {
      onCommit();
    }
  };

  return (
    <ListItem
      ref={itemRef}
      onBlur={handleBlur}
      sx={{ display: 'block', px: 0, py: 2 }}
    >
      <Stack direction="row" alignItems="center">
        <ListItemIcon>
          <PinPropertyIconPicker
            icon={draft.icon}
            disabled={disabled}
            onChange={(icon) => onChange((current) => ({ ...current, icon }))}
          />
        </ListItemIcon>
        <form onSubmit={handleSubmit} style={{ flex: 1, minWidth: 0 }}>
          <TextField
            label={dictionary['pin property name']}
            value={draft.name}
            onChange={(event) => {
              const name = event.target.value;
              onChange((current) => ({ ...current, name }));
            }}
            error={tooLong}
            helperText={tooLong && dictionary['max characters 30']}
            disabled={disabled}
            size="small"
            fullWidth
            autoFocus
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <Box
                      component="span"
                      role="img"
                      aria-label={typeLabel}
                      sx={{ display: 'flex' }}
                    >
                      <PinPropertyTypeIcon
                        multiple={draft.multiple}
                        fontSize="small"
                      />
                    </Box>
                  </InputAdornment>
                )
              }
            }}
          />
        </form>
        <Box sx={{ ml: 1 }}>
          <PinPropertyColorPicker
            color={draft.color}
            disabled={disabled}
            onChange={(color) => onChange((current) => ({ ...current, color }))}
          />
        </Box>
        <IconButton
          edge="end"
          aria-label={dictionary.cancel}
          title={dictionary.cancel}
          disabled={disabled}
          onClick={onCancel}
        >
          <Close />
        </IconButton>
      </Stack>

      <List
        disablePadding
        subheader={
          <ListSubheader disableGutters disableSticky>
            {dictionary['pin property options']}
          </ListSubheader>
        }
        sx={{ pl: 7 }}
      >
        {draft.options.map((option) => (
          <ListItem
            key={option}
            disableGutters
            secondaryAction={
              <IconButton
                edge="end"
                aria-label={dictionary.delete}
                title={dictionary.delete}
                disabled={disabled}
                onClick={() =>
                  onChange((current) => ({
                    ...current,
                    options: current.options.filter((name) => name !== option)
                  }))
                }
              >
                <DeleteOutline />
              </IconButton>
            }
          >
            <ListItemIcon>
              <PinPropertyIcon icon={draft.icon} />
            </ListItemIcon>
            <ListItemText primary={option} />
          </ListItem>
        ))}
        <PinPropertyOptionAddField
          value={draft.optionInput}
          disabled={disabled}
          onChange={(optionInput) =>
            onChange((current) => ({ ...current, optionInput }))
          }
          onAdd={(name) =>
            onChange((current) => ({
              ...current,
              options: uniqueNames([...current.options, name]),
              optionInput: ''
            }))
          }
        />
      </List>
    </ListItem>
  );
}
