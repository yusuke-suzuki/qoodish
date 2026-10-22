import {
  type ReactNode,
  useEffect,
  useEffectEvent,
  useRef,
  useState
} from 'react';
import { createPortal } from 'react-dom';
import { useGoogleMap } from '../../hooks/useGoogleMap.ts';

type Props = {
  children: ReactNode;
  position: google.maps.LatLng | null;
  onClick?: () => void;
  onMouseEnter?: () => void;
  onMouseLeave?: () => void;
};

export default function MarkerView({
  children,
  position,
  onClick,
  onMouseEnter,
  onMouseLeave
}: Props) {
  const { loader, googleMap } = useGoogleMap();

  // The marker is an imperative map object that the effects below write to, so
  // it is held in a ref rather than in state; the flag is what lets them run
  // once it exists.
  const markerRef = useRef<google.maps.marker.AdvancedMarkerElement | null>(
    null
  );
  const [ready, setReady] = useState(false);

  // The marker holds this element, so the portal has to keep rendering into
  // the same one. A lazy initial state guarantees that; useMemo does not.
  const [content] = useState<HTMLDivElement>(() => {
    const element = document.createElement('div');
    element.style.cursor = 'pointer';

    return element;
  });

  const handleClick = useEffectEvent(() => onClick?.());
  const handleMouseEnter = useEffectEvent(() => onMouseEnter?.());
  const handleMouseLeave = useEffectEvent(() => onMouseLeave?.());

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

      const marker = new AdvancedMarkerElement({
        map: googleMap,
        content: content
      });

      markerRef.current = marker;

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
  }, [googleMap, loader, content]);

  useEffect(() => {
    // Turning on gmpClickable to use gmp-click makes the marker swallow taps
    // around it, which stops the visitor panning the map from there, so the
    // listeners go on the content this component renders itself.
    const click = () => handleClick();
    const mouseEnter = () => handleMouseEnter();
    const mouseLeave = () => handleMouseLeave();

    content.addEventListener('click', click);
    content.addEventListener('mouseenter', mouseEnter);
    content.addEventListener('mouseleave', mouseLeave);

    return () => {
      content.removeEventListener('click', click);
      content.removeEventListener('mouseenter', mouseEnter);
      content.removeEventListener('mouseleave', mouseLeave);
    };
  }, [content]);

  useEffect(() => {
    const marker = markerRef.current;

    if (!ready || !marker || !position) {
      return;
    }

    marker.position = position;
  }, [ready, position]);

  return createPortal(children, content);
}
