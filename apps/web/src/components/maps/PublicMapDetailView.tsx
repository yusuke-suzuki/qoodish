import {
  CHAPTERS_TAG,
  CONTENT_TAG,
  mapTag,
  userTag
} from '../../lib/cacheTags.ts';
import {
  getMap,
  getMapChapters,
  getMapCoauthors,
  getMapPinProperties,
  getMapPins
} from '../../lib/maps.ts';
import { cachePublic } from '../../lib/publicCache.ts';
import { mapStructuredData } from '../../utils/structuredData.ts';
import JsonLd from '../common/JsonLd.tsx';
import MapDetailView from './MapDetailView.tsx';

type Props = {
  mapId: string;
  lang: string;
};

export default async function PublicMapDetailView({ mapId, lang }: Props) {
  'use cache';
  await cachePublic(300, [mapTag(mapId), CHAPTERS_TAG, CONTENT_TAG]);

  const [map, pins, pinProperties, coauthors, chapters] = await Promise.all([
    getMap(mapId, lang),
    getMapPins(mapId, lang),
    getMapPinProperties(mapId, lang),
    getMapCoauthors(mapId, lang),
    getMapChapters(mapId, lang)
  ]);

  if (!map) {
    return null;
  }

  await cachePublic(300, [
    ...new Set(
      [map.author.id, ...coauthors.map((coauthor) => coauthor.id)].map(userTag)
    )
  ]);

  return (
    <>
      <JsonLd data={mapStructuredData(map, pins, lang)} />
      <MapDetailView
        map={map}
        pins={pins}
        pinProperties={pinProperties}
        coauthors={coauthors}
        chapters={chapters}
        currentProfile={null}
        currentJourney={null}
      />
    </>
  );
}
