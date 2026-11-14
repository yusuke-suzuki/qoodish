import { CONTENT_TAG, mapTag, pinTag } from '../../lib/cacheTags.ts';
import { getMap, getMapPinProperties } from '../../lib/maps.ts';
import { getPin } from '../../lib/pins.ts';
import { cachePublic } from '../../lib/publicCache.ts';
import PinDetail from './PinDetail.tsx';

type Props = {
  pinId: string;
  lang: string;
};

export default async function PublicPinDetail({ pinId, lang }: Props) {
  'use cache';
  await cachePublic(300, [pinTag(pinId), CONTENT_TAG]);
  const pin = await getPin(pinId, lang);

  if (!pin) {
    return null;
  }

  const mapId = String(pin.map.id);
  await cachePublic(300, [mapTag(mapId)]);

  const [map, pinProperties] = await Promise.all([
    getMap(mapId, lang),
    getMapPinProperties(mapId, lang)
  ]);

  return <PinDetail pin={pin} map={map} pinProperties={pinProperties} />;
}
