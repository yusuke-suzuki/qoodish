import { Navigation } from '@mui/icons-material';
import { useEffect, useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';
import { useGoogleMap } from '../../hooks/useGoogleMap.ts';
import MapControlButton, { GLYPH_SIZE } from './MapControlButton.tsx';

// A vector map turns and tilts under two-finger gestures, but offers no
// control that brings it back, so this compass appears once it has moved.
function ResetHeadingButton() {
  const { googleMap } = useGoogleMap();
  const dictionary = useDictionary();

  const [heading, setHeading] = useState(0);
  const [tilt, setTilt] = useState(0);

  useEffect(() => {
    if (!googleMap) {
      return;
    }

    const headingListener = googleMap.addListener('heading_changed', () =>
      setHeading(googleMap.getHeading() ?? 0)
    );
    const tiltListener = googleMap.addListener('tilt_changed', () =>
      setTilt(googleMap.getTilt() ?? 0)
    );

    return () => {
      headingListener.remove();
      tiltListener.remove();
    };
  }, [googleMap]);

  if (!googleMap || (heading === 0 && tilt === 0)) {
    return null;
  }

  return (
    <MapControlButton
      onClick={() => googleMap.moveCamera({ heading: 0, tilt: 0 })}
      label={dictionary['reset map heading']}
    >
      {/* The arrow points to the north, wherever the map has turned it. */}
      <Navigation
        sx={{
          fontSize: GLYPH_SIZE,
          color: '#d93025',
          transform: `rotate(${-heading}deg)`
        }}
      />
    </MapControlButton>
  );
}

export default ResetHeadingButton;
