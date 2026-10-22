import { useEffect, useEffectEvent, useRef, useState } from 'react';
import { useGoogleMap } from '../../hooks/useGoogleMap.ts';

type Props = {
  defaultPosition?: google.maps.LatLng | google.maps.LatLngLiteral | null;
  onLatLngChanged: (center: google.maps.LatLngLiteral) => void;
};

export default function DraggableMarker({
  defaultPosition,
  onLatLngChanged
}: Props) {
  const { googleMap, loader } = useGoogleMap();

  // The marker is an imperative map object that the effects below write to, so
  // it is held in a ref rather than in state; the flag is what lets them run
  // once it exists.
  const markerRef = useRef<google.maps.marker.AdvancedMarkerElement | null>(
    null
  );
  const [ready, setReady] = useState(false);

  const handleDragEnd = useEffectEvent(
    ({ latLng }: google.maps.MapMouseEvent) => {
      if (!latLng) {
        return;
      }

      onLatLngChanged({
        lat: latLng.lat(),
        lng: latLng.lng()
      });
    }
  );

  useEffect(() => {
    if (!googleMap || !loader) {
      return;
    }

    let cancelled = false;

    const initMarker = async () => {
      const { AdvancedMarkerElement } = await loader.importLibrary('marker');

      if (cancelled) {
        return;
      }

      markerRef.current = new AdvancedMarkerElement({
        map: googleMap,
        gmpDraggable: true,
        zIndex: 2
      });

      setReady(true);
    };

    initMarker();

    return () => {
      cancelled = true;

      if (markerRef.current) {
        markerRef.current.map = null;
        markerRef.current = null;
      }

      setReady(false);
    };
  }, [googleMap, loader]);

  useEffect(() => {
    const marker = markerRef.current;

    if (!ready || !marker) {
      return;
    }

    const listener = marker.addListener(
      'dragend',
      (event: google.maps.MapMouseEvent) => handleDragEnd(event)
    );

    return () => {
      listener.remove();
    };
  }, [ready]);

  useEffect(() => {
    const marker = markerRef.current;

    if (!ready || !marker || !defaultPosition) {
      return;
    }

    marker.position = defaultPosition;
  }, [ready, defaultPosition]);

  return null;
}
