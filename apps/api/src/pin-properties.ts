import type {
  PinProperty,
  PinPropertyOption as PinPropertyOptionShape
} from '@qoodish/api-contract';
import { and, asc, eq, inArray, type SQL, type SQLWrapper } from 'drizzle-orm';
import { z } from 'zod';
import {
  changedColumns,
  currentTimestamp,
  type Database
} from './db/client.ts';
import { pinProperties, pinPropertyOptions } from './db/schema.ts';
import { ApiError } from './errors.ts';
import type { MessageKey } from './i18n/index.ts';
import { first } from './routing.ts';
import { characters, graphemes } from './text.ts';
import { position } from './validation.ts';

const NAME_LIMIT = 30;

function tagName({
  required,
  exceed
}: {
  required: MessageKey;
  exceed: MessageKey;
}) {
  return z
    .string({ error: required })
    .trim()
    .refine((name) => name !== '', { error: required })
    .refine((name) => characters(name) <= NAME_LIMIT, { error: exceed });
}

const propertyName = tagName({
  required: 'pin_property_name_required',
  exceed: 'pin_property_name_exceed'
});

const optionName = tagName({
  required: 'pin_property_option_name_required',
  exceed: 'pin_property_option_name_exceed'
});

const ICON_LENGTH_LIMIT = 32;

function tagIcon(invalid: MessageKey) {
  return z
    .string({ error: invalid })
    .trim()
    .refine(
      (icon) => graphemes(icon) === 1 && icon.length <= ICON_LENGTH_LIMIT,
      { error: invalid }
    )
    .nullable();
}

const propertyIcon = tagIcon('pin_property_icon_invalid');

const optionIcon = tagIcon('pin_property_option_icon_invalid');

const propertyColor = z
  .string({ error: 'pin_property_color_invalid' })
  .regex(/^#[0-9a-f]{6}$/i, { error: 'pin_property_color_invalid' })
  .transform((color) => color.toLowerCase())
  .nullable();

export const newPinPropertyInput = z.object({
  name: propertyName,
  position: position.optional(),
  multiple: z.boolean().optional(),
  icon: propertyIcon.optional(),
  color: propertyColor.optional()
});

export const pinPropertyInput = z.object({
  name: propertyName.optional(),
  position: position.optional(),
  icon: propertyIcon.optional(),
  color: propertyColor.optional()
});

export const newPinPropertyOptionInput = z.object({
  name: optionName,
  position: position.optional(),
  icon: optionIcon.optional()
});

export const pinPropertyOptionInput = z.object({
  name: optionName.optional(),
  position: position.optional(),
  icon: optionIcon.optional()
});

type Status = 'published' | 'deleted';

type NamedContent = { name: string; position: number; status: Status };

type NamedChanges = { name?: string; position?: number };

type PropertyRow = typeof pinProperties.$inferSelect;
type OptionRow = typeof pinPropertyOptions.$inferSelect;

function contentOf(row: PropertyRow | OptionRow): NamedContent {
  return {
    name: row.name,
    position: row.position,
    status: row.status === 'deleted' ? 'deleted' : 'published'
  };
}

type NamedEdit = { changes?: NamedChanges; status?: Status };

type Appearance = { icon: string | null; color: string | null };

type PropertyEdit = {
  changes?: NamedChanges & Partial<Appearance>;
  status?: Status;
};

type OptionEdit = {
  changes?: NamedChanges & Partial<Pick<Appearance, 'icon'>>;
  status?: Status;
};

function changedContent(
  row: PropertyRow | OptionRow,
  { changes, status }: NamedEdit
): Partial<NamedContent> {
  const current = contentOf(row);

  return changedColumns(current, {
    name: changes?.name ?? current.name,
    position: changes?.position ?? current.position,
    status: status ?? current.status
  });
}

function changedPropertyContent(
  property: PropertyRow,
  edit: PropertyEdit
): Partial<NamedContent & Appearance> {
  const current = { icon: property.icon, color: property.color };

  return {
    ...changedContent(property, edit),
    ...changedColumns(current, {
      icon: edit.changes?.icon === undefined ? current.icon : edit.changes.icon,
      color:
        edit.changes?.color === undefined ? current.color : edit.changes.color
    })
  };
}

function changedOptionContent(
  option: OptionRow,
  edit: OptionEdit
): Partial<NamedContent & Pick<Appearance, 'icon'>> {
  const current = { icon: option.icon };

  return {
    ...changedContent(option, edit),
    ...changedColumns(current, {
      icon: edit.changes?.icon === undefined ? current.icon : edit.changes.icon
    })
  };
}

export async function editablePinProperty(
  db: Database,
  { id, mapId }: { id: number; mapId: SQL }
): Promise<PropertyRow> {
  return first(
    await db
      .select()
      .from(pinProperties)
      .where(
        and(
          eq(pinProperties.id, id),
          eq(pinProperties.status, 'published'),
          eq(pinProperties.mapId, mapId)
        )
      )
  );
}

export async function publishedOption(
  db: Database,
  { id, propertyId }: { id: number; propertyId: number }
): Promise<OptionRow> {
  return first(
    await db
      .select()
      .from(pinPropertyOptions)
      .where(
        and(
          eq(pinPropertyOptions.id, id),
          eq(pinPropertyOptions.pinPropertyId, propertyId),
          eq(pinPropertyOptions.status, 'published')
        )
      )
  );
}

export async function createPinProperty(
  db: Database,
  {
    mapId,
    changes
  }: { mapId: number; changes: z.output<typeof newPinPropertyInput> }
): Promise<number> {
  const now = currentTimestamp();
  const created = await db
    .insert(pinProperties)
    .values({
      name: changes.name,
      position: changes.position ?? 0,
      multiple: changes.multiple ?? false,
      icon: changes.icon ?? null,
      color: changes.color ?? null,
      status: 'published',
      mapId,
      createdAt: now,
      updatedAt: now
    })
    .returning({ id: pinProperties.id });

  return first(created).id;
}

export async function revisePinProperty(
  db: Database,
  property: PropertyRow,
  edit: PropertyEdit
): Promise<void> {
  const changes = changedPropertyContent(property, edit);

  if (Object.keys(changes).length === 0) {
    return;
  }

  first(
    await db
      .update(pinProperties)
      .set({ ...changes, updatedAt: currentTimestamp() })
      .where(
        and(
          eq(pinProperties.id, property.id),
          eq(pinProperties.status, 'published')
        )
      )
      .returning({ id: pinProperties.id })
  );
}

export async function createPinPropertyOption(
  db: Database,
  {
    propertyId,
    changes
  }: {
    propertyId: number;
    changes: z.output<typeof newPinPropertyOptionInput>;
  }
): Promise<number> {
  const now = currentTimestamp();
  const created = await db
    .insert(pinPropertyOptions)
    .values({
      name: changes.name,
      position: changes.position ?? 0,
      icon: changes.icon ?? null,
      status: 'published',
      pinPropertyId: propertyId,
      createdAt: now,
      updatedAt: now
    })
    .returning({ id: pinPropertyOptions.id });

  return first(created).id;
}

export async function revisePinPropertyOption(
  db: Database,
  option: OptionRow,
  edit: OptionEdit
): Promise<void> {
  const changes = changedOptionContent(option, edit);

  if (Object.keys(changes).length === 0) {
    return;
  }

  first(
    await db
      .update(pinPropertyOptions)
      .set({ ...changes, updatedAt: currentTimestamp() })
      .where(
        and(
          eq(pinPropertyOptions.id, option.id),
          eq(pinPropertyOptions.status, 'published')
        )
      )
      .returning({ id: pinPropertyOptions.id })
  );
}

export async function pinPropertyDetail(
  db: Database,
  propertyId: number
): Promise<PinProperty> {
  const [[property], options] = await db.batch([
    db.select().from(pinProperties).where(eq(pinProperties.id, propertyId)),
    db
      .select()
      .from(pinPropertyOptions)
      .where(
        and(
          eq(pinPropertyOptions.pinPropertyId, propertyId),
          eq(pinPropertyOptions.status, 'published')
        )
      )
      .orderBy(asc(pinPropertyOptions.position), asc(pinPropertyOptions.id))
  ]);

  if (!property) {
    throw new ApiError('NotFound');
  }

  return propertyShape(property, options);
}

export function propertyShape(
  property: PropertyRow,
  options: readonly OptionRow[]
): PinProperty {
  return {
    id: property.id,
    name: property.name,
    multiple: property.multiple,
    position: property.position,
    icon: property.icon,
    color: property.color,
    options: options.map(optionShape)
  };
}

export function optionShape(option: OptionRow): PinPropertyOptionShape {
  return {
    id: option.id,
    name: option.name,
    position: option.position,
    icon: option.icon
  };
}

export async function pinPropertyOptionDetail(
  db: Database,
  optionId: number
): Promise<PinPropertyOptionShape> {
  return optionShape(
    first(
      await db
        .select()
        .from(pinPropertyOptions)
        .where(eq(pinPropertyOptions.id, optionId))
    )
  );
}

export function pinPropertiesDeletion(db: Database, propertyIds: SQLWrapper) {
  return [
    db
      .delete(pinPropertyOptions)
      .where(inArray(pinPropertyOptions.pinPropertyId, propertyIds)),
    db.delete(pinProperties).where(inArray(pinProperties.id, propertyIds))
  ] as const;
}
