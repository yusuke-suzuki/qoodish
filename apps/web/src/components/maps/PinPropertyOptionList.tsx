'use client';

import { DeleteOutline } from '@mui/icons-material';
import {
  CircularProgress,
  IconButton,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListSubheader
} from '@mui/material';
import { useState } from 'react';
import type { PinProperty, PinPropertyOption } from '../../../types/index.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import type { PinPropertyOptionChanges } from '../../utils/pinPropertyOptions.ts';
import NameEditField from './NameEditField.tsx';
import PinPropertyIconPicker from './PinPropertyIconPicker.tsx';
import PinPropertyOptionAddField from './PinPropertyOptionAddField.tsx';

type Props = {
  property: PinProperty;
  onCreate: (name: string) => Promise<boolean>;
  onUpdate: (
    option: PinPropertyOption,
    changes: PinPropertyOptionChanges
  ) => Promise<boolean>;
  onDelete: (option: PinPropertyOption) => void;
};

export default function PinPropertyOptionList({
  property,
  onCreate,
  onUpdate,
  onDelete
}: Props) {
  const dictionary = useDictionary();
  const { options } = property;

  const [input, setInput] = useState('');
  const [pendingNames, setPendingNames] = useState<string[]>([]);
  const [shownOptions, setShownOptions] = useState(options);

  if (options !== shownOptions) {
    setShownOptions(options);
    setPendingNames((names) =>
      names.filter((name) => !options.some((option) => option.name === name))
    );
  }

  const create = async (name: string) => {
    setInput('');

    if (
      options.some((option) => option.name === name) ||
      pendingNames.includes(name)
    ) {
      return;
    }

    setPendingNames((names) => [...names, name]);

    if (!(await onCreate(name).catch(() => false))) {
      setPendingNames((names) => names.filter((pending) => pending !== name));
      setInput((current) => current || name);
    }
  };

  const tagIcon = {
    icon: property.icon,
    label: dictionary['use tag icon']
  };

  return (
    <List
      disablePadding
      subheader={
        <ListSubheader disableGutters disableSticky>
          {dictionary['pin property options']}
        </ListSubheader>
      }
    >
      {options.map((option) => (
        <ListItem
          key={option.id}
          disableGutters
          secondaryAction={
            <IconButton
              edge="end"
              aria-label={dictionary.delete}
              title={dictionary.delete}
              onClick={() => onDelete(option)}
            >
              <DeleteOutline />
            </IconButton>
          }
        >
          <ListItemIcon>
            <PinPropertyIconPicker
              icon={option.icon}
              fallback={tagIcon}
              onChange={(icon) => onUpdate(option, { icon })}
            />
          </ListItemIcon>
          <NameEditField
            label={dictionary['pin property option name']}
            hideLabel
            defaultValue={option.name}
            onSave={(name) => onUpdate(option, { name })}
          />
        </ListItem>
      ))}
      {pendingNames.map((name) => (
        <ListItem key={name} disableGutters>
          <ListItemIcon>
            <CircularProgress size={24} />
          </ListItemIcon>
          <ListItemText primary={name} />
        </ListItem>
      ))}
      <PinPropertyOptionAddField
        value={input}
        onChange={setInput}
        onAdd={create}
      />
    </List>
  );
}
