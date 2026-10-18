import type { CountedMap, Pin } from '../../types/index.ts';
import fetchApiList from './fetchApiList.ts';

export function fetchRelatedMaps(): Promise<CountedMap[]> {
  return fetchApiList<CountedMap>('v2/maps');
}

export function fetchMapPins(mapId: number): Promise<Pin[]> {
  return fetchApiList<Pin>(`maps/${mapId}/pins`);
}
