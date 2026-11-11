'use client';

import { Add } from '@mui/icons-material';
import {
  Button,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem
} from '@mui/material';
import { useRouter } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { useRef, useState, useTransition } from 'react';
import type {
  AppMap,
  PinProperty,
  PinPropertyOption
} from '../../../types/index.ts';
import {
  createPinProperty,
  createPinPropertyOption,
  deletePinProperty,
  deletePinPropertyOption,
  updatePinProperty,
  updatePinPropertyOption
} from '../../actions/pinProperties.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import AppDialog from '../common/AppDialog.tsx';
import ConfirmDialog from '../common/ConfirmDialog.tsx';
import NewPinPropertyListItem, {
  draftCommittable,
  draftOptionNames,
  EMPTY_DRAFT,
  type PinPropertyDraft
} from './NewPinPropertyListItem.tsx';
import PinPropertyListItem from './PinPropertyListItem.tsx';
import PinPropertyTypeIcon from './PinPropertyTypeIcon.tsx';

type DeleteTarget =
  | { kind: 'property'; property: PinProperty }
  | { kind: 'option'; property: PinProperty; option: PinPropertyOption };

type Props = {
  open: boolean;
  onClose: () => void;
  map: AppMap;
  pinProperties: PinProperty[];
};

export default function PinPropertiesDialog({
  open,
  onClose,
  map,
  pinProperties
}: Props) {
  const dictionary = useDictionary();
  const router = useRouter();

  const [deleteTarget, setDeleteTarget] = useState<DeleteTarget | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [draft, setDraft] = useState<PinPropertyDraft | null>(null);
  const [createdId, setCreatedId] = useState<number | null>(null);
  const [isCreating, startCreating] = useTransition();
  const committingRef = useRef(false);
  const [typeMenuAnchor, setTypeMenuAnchor] = useState<HTMLElement | null>(
    null
  );
  const [chosenMultiple, setChosenMultiple] = useState<boolean | null>(null);

  const draftShown =
    draft !== null &&
    !(
      createdId !== null &&
      pinProperties.some((property) => property.id === createdId)
    );

  const openDelete = (target: DeleteTarget) => {
    setDeleteTarget(target);
    setDeleteOpen(true);
  };

  const finish = (result: { success: boolean; error?: string }) => {
    if (result.success) {
      router.refresh();
    }

    if (result.error || !result.success) {
      enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
        variant: 'error'
      });
    }

    return result.success;
  };

  const commitDraft = () => {
    if (
      !draft ||
      !draftCommittable(draft) ||
      createdId !== null ||
      committingRef.current
    ) {
      return;
    }

    committingRef.current = true;

    const { options, optionInput, ...tag } = draft;
    const optionNames = draftOptionNames(draft);

    startCreating(async () => {
      try {
        const result = await createPinProperty(map.id, {
          ...tag,
          name: tag.name.trim()
        });

        if (!result.success || result.id === undefined) {
          enqueueSnackbar(result.error ?? dictionary['an error occurred'], {
            variant: 'error'
          });
          return;
        }

        for (const name of optionNames) {
          const option = await createPinPropertyOption(map.id, result.id, {
            name
          });

          if (option.error) {
            enqueueSnackbar(option.error, { variant: 'error' });
          }
        }

        setCreatedId(result.id);
        router.refresh();
      } catch (_error) {
        enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
      } finally {
        committingRef.current = false;
      }
    });
  };

  const chooseType = (multiple: boolean) => {
    setChosenMultiple(multiple);
    setTypeMenuAnchor(null);
  };

  const startChosenDraft = () => {
    if (chosenMultiple === null) {
      return;
    }

    setCreatedId(null);
    setDraft({ ...EMPTY_DRAFT, multiple: chosenMultiple });
    setChosenMultiple(null);
  };

  const handleClose = () => {
    commitDraft();
    onClose();
  };

  const handleExited = () => {
    setDraft(null);
    setCreatedId(null);
  };

  const handleDelete = async () => {
    if (!deleteTarget) {
      return;
    }

    const result =
      deleteTarget.kind === 'property'
        ? await deletePinProperty(map.id, deleteTarget.property.id)
        : await deletePinPropertyOption(
            map.id,
            deleteTarget.property.id,
            deleteTarget.option.id
          );

    if (finish(result)) {
      setDeleteOpen(false);
    }
  };

  return (
    <>
      <AppDialog
        open={open}
        onClose={handleClose}
        onExited={handleExited}
        title={dictionary['pin properties']}
        fullScreenOnMobile
        dividers
        cancelLabel={dictionary.close}
      >
        <List disablePadding>
          {pinProperties.map((property) => (
            <PinPropertyListItem
              key={property.id}
              property={property}
              onRename={async (name) =>
                finish(await updatePinProperty(map.id, property.id, { name }))
              }
              onChangeAppearance={async (appearance) =>
                finish(await updatePinProperty(map.id, property.id, appearance))
              }
              onDelete={() => openDelete({ kind: 'property', property })}
              onCreateOption={async (name) =>
                finish(
                  await createPinPropertyOption(map.id, property.id, { name })
                )
              }
              onUpdateOption={async (option, changes) =>
                finish(
                  await updatePinPropertyOption(
                    map.id,
                    property.id,
                    option.id,
                    changes
                  )
                )
              }
              onDeleteOption={(option) =>
                openDelete({ kind: 'option', property, option })
              }
            />
          ))}
          {draftShown && (
            <NewPinPropertyListItem
              draft={draft}
              disabled={isCreating || createdId !== null}
              onChange={(update) =>
                setDraft((current) => current && update(current))
              }
              onCommit={commitDraft}
              onCancel={() => setDraft(null)}
            />
          )}
          <ListItem disableGutters>
            <Button
              startIcon={<Add />}
              aria-haspopup="true"
              aria-expanded={Boolean(typeMenuAnchor)}
              disabled={draftShown}
              onClick={(event) => setTypeMenuAnchor(event.currentTarget)}
            >
              {dictionary['add pin property']}
            </Button>
          </ListItem>
        </List>
        <Menu
          anchorEl={typeMenuAnchor}
          open={Boolean(typeMenuAnchor)}
          onClose={() => setTypeMenuAnchor(null)}
          slotProps={{ transition: { onExited: startChosenDraft } }}
        >
          {[false, true].map((multiple) => (
            <MenuItem
              key={String(multiple)}
              onClick={() => chooseType(multiple)}
            >
              <ListItemIcon>
                <PinPropertyTypeIcon multiple={multiple} fontSize="small" />
              </ListItemIcon>
              <ListItemText
                primary={
                  multiple
                    ? dictionary['multi select']
                    : dictionary['single select']
                }
              />
            </MenuItem>
          ))}
        </Menu>
      </AppDialog>

      <ConfirmDialog
        open={deleteOpen}
        title={
          deleteTarget?.kind === 'option'
            ? dictionary['sure to delete pin property option']
            : dictionary['sure to delete pin property']
        }
        description={
          deleteTarget?.kind === 'option'
            ? dictionary['delete pin property option detail']
            : dictionary['delete pin property detail']
        }
        confirmLabel={dictionary.delete}
        confirmColor="error"
        onClose={() => setDeleteOpen(false)}
        onConfirm={handleDelete}
      />
    </>
  );
}
