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
import {
  pinProperties,
  pinPropertyOptionRevisions,
  pinPropertyOptions,
  pinPropertyRevisions
} from './db/schema.ts';
import { ApiError } from './errors.ts';
import type { MessageKey } from './i18n/index.ts';
import { first } from './routing.ts';
import { characters } from './text.ts';
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

export const newPinPropertyInput = z.object({
  name: propertyName,
  position: position.optional(),
  multiple: z.boolean().optional()
});

export const pinPropertyInput = z.object({
  name: propertyName.optional(),
  position: position.optional()
});

export const newPinPropertyOptionInput = z.object({
  name: optionName,
  position: position.optional()
});

export const pinPropertyOptionInput = z.object({
  name: optionName.optional(),
  position: position.optional()
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
  edit: NamedEdit
): Promise<void> {
  const changes = changedContent(property, edit);

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
  edit: NamedEdit
): Promise<void> {
  const changes = changedContent(option, edit);

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

  return {
    id: property.id,
    name: property.name,
    multiple: property.multiple,
    position: property.position,
    options: options.map(optionShape)
  };
}

export function optionShape(option: OptionRow): PinPropertyOptionShape {
  return { id: option.id, name: option.name, position: option.position };
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
  const optionIds = db
    .select({ id: pinPropertyOptions.id })
    .from(pinPropertyOptions)
    .where(inArray(pinPropertyOptions.pinPropertyId, propertyIds));

  return [
    db
      .delete(pinPropertyOptionRevisions)
      .where(
        inArray(pinPropertyOptionRevisions.pinPropertyOptionId, optionIds)
      ),
    db
      .delete(pinPropertyOptions)
      .where(inArray(pinPropertyOptions.pinPropertyId, propertyIds)),
    db
      .delete(pinPropertyRevisions)
      .where(inArray(pinPropertyRevisions.pinPropertyId, propertyIds)),
    db.delete(pinProperties).where(inArray(pinProperties.id, propertyIds))
  ] as const;
}
