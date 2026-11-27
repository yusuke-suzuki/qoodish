import { createContext } from 'react';

export type LoadLibrary = <Name extends keyof google.maps.ImportLibraryMap>(
  name: Name
) => Promise<google.maps.ImportLibraryMap[Name] | null>;

type ContextProps = {
  googleMap: google.maps.Map | null;
  loadLibrary: LoadLibrary | null;
  currentPosition: GeolocationPosition | null;
  setCurrentPosition: (position: GeolocationPosition) => void;
};

const GoogleMapsContext = createContext<ContextProps>({
  googleMap: null,
  loadLibrary: null,
  currentPosition: null,
  setCurrentPosition: () => {}
});

export default GoogleMapsContext;
