import type {
  Journey,
  JourneyCheckin,
  MapFeature,
  MapFeatureCollection,
  Spot
} from '../../types/index.ts';

export function visitedSpots(checkins: JourneyCheckin[]): Spot[] {
  const spots = new Map<number | string, Spot>();

  for (const checkin of checkins.toSorted((a, b) =>
    a.checked_in_at.localeCompare(b.checked_in_at)
  )) {
    const key = checkin.pin_id ?? `checkin:${checkin.id}`;

    if (!spots.has(key)) {
      spots.set(key, checkin.spot);
    }
  }

  return [...spots.values()];
}

export function spotFeature(spot: Spot): MapFeature {
  return {
    type: 'Feature',
    geometry: {
      type: 'Point',
      coordinates: [spot.longitude, spot.latitude]
    },
    properties: { title: spot.name }
  };
}

export function createMapFeatures(journey: Journey): MapFeatureCollection {
  return {
    type: 'FeatureCollection',
    features: visitedSpots(journey.checkins).map(spotFeature)
  };
}

export function featureSpots(collection: MapFeatureCollection): Spot[] {
  return (collection.features ?? [])
    .filter((feature) => feature.geometry?.type === 'Point')
    .map((feature) => ({
      name: feature.properties?.title ?? '',
      longitude: feature.geometry.coordinates[0],
      latitude: feature.geometry.coordinates[1]
    }));
}
