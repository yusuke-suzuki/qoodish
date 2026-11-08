'use server';

import type { PinProperty } from '../../types/index.ts';
import { apiFetch } from '../lib/api.ts';
import { mapTag } from '../lib/cacheTags.ts';
import { revalidateTags } from '../lib/revalidate.ts';
import type { PinPropertyAppearance } from '../utils/pinPropertyOptions.ts';

type ActionResult = {
  success: boolean;
  error?: string;
};

async function mutateMap(
  mapId: number,
  path: string,
  init: RequestInit
): Promise<ActionResult> {
  const { error } = await apiFetch(
    `/maps/${mapId}/pin_properties${path}`,
    init
  );

  if (error) {
    return { success: false, error };
  }

  revalidateTags([mapTag(mapId)]);

  return { success: true };
}

export async function createPinProperty(
  mapId: number,
  params: PinPropertyAppearance & { name: string; multiple: boolean }
): Promise<ActionResult & { id?: number }> {
  const { data, error } = await apiFetch<PinProperty>(
    `/maps/${mapId}/pin_properties`,
    { method: 'POST', body: JSON.stringify(params) }
  );

  if (error || !data) {
    return { success: false, error: error ?? undefined };
  }

  revalidateTags([mapTag(mapId)]);

  return { success: true, id: data.id };
}

export async function updatePinProperty(
  mapId: number,
  propertyId: number,
  params: { name: string } | Partial<PinPropertyAppearance>
): Promise<ActionResult> {
  return mutateMap(mapId, `/${propertyId}`, {
    method: 'PUT',
    body: JSON.stringify(params)
  });
}

export async function deletePinProperty(
  mapId: number,
  propertyId: number
): Promise<ActionResult> {
  return mutateMap(mapId, `/${propertyId}`, { method: 'DELETE' });
}

export async function createPinPropertyOption(
  mapId: number,
  propertyId: number,
  params: { name: string }
): Promise<ActionResult> {
  return mutateMap(mapId, `/${propertyId}/options`, {
    method: 'POST',
    body: JSON.stringify(params)
  });
}

export async function updatePinPropertyOption(
  mapId: number,
  propertyId: number,
  optionId: number,
  params: { name: string }
): Promise<ActionResult> {
  return mutateMap(mapId, `/${propertyId}/options/${optionId}`, {
    method: 'PUT',
    body: JSON.stringify(params)
  });
}

export async function deletePinPropertyOption(
  mapId: number,
  propertyId: number,
  optionId: number
): Promise<ActionResult> {
  return mutateMap(mapId, `/${propertyId}/options/${optionId}`, {
    method: 'DELETE'
  });
}
