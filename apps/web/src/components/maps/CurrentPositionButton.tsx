import { LocationSearching, MyLocation } from '@mui/icons-material';
import { CircularProgress } from '@mui/material';
import { useState } from 'react';
import useDictionary from '../../hooks/useDictionary.ts';
import { useGoogleMap } from '../../hooks/useGoogleMap.ts';
import MapControlButton, { GLYPH_SIZE } from './MapControlButton.tsx';

const PROGRESS_SIZE = 18;

function CurrentPositionButton() {
  const { googleMap, currentPosition, setCurrentPosition } = useGoogleMap();
  const dictionary = useDictionary();

  const [loading, setLoading] = useState<boolean>(false);

  const handlePosition = (position: GeolocationPosition) => {
    setLoading(false);

    if (!googleMap) {
      return;
    }

    setCurrentPosition(position);

    googleMap.panTo({
      lat: position.coords.latitude,
      lng: position.coords.longitude
    });
    googleMap.setZoom(17);
  };

  const handlePositionError = (positionError: GeolocationPositionError) => {
    console.error(positionError);
    setLoading(false);
  };

  const handleClick = () => {
    setLoading(true);

    navigator.geolocation.getCurrentPosition(
      handlePosition,
      handlePositionError,
      {
        enableHighAccuracy: false,
        maximumAge: 30000
      }
    );
  };

  return (
    <MapControlButton
      onClick={handleClick}
      label={dictionary['current position']}
    >
      {loading ? (
        <CircularProgress size={PROGRESS_SIZE} color="inherit" />
      ) : currentPosition ? (
        <MyLocation sx={{ fontSize: GLYPH_SIZE, color: '#1A73E8' }} />
      ) : (
        <LocationSearching sx={{ fontSize: GLYPH_SIZE }} />
      )}
    </MapControlButton>
  );
}

export default CurrentPositionButton;
