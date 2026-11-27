import { createContext } from 'react';

export type ImportMapsLibrary = <
  Name extends keyof google.maps.ImportLibraryMap
>(
  name: Name
) => Promise<google.maps.ImportLibraryMap[Name]>;

type ContextProps = {
  googleMap: google.maps.Map | null;
  importLibrary: ImportMapsLibrary | null;
  currentPosition: GeolocationPosition | null;
  setCurrentPosition: (position: GeolocationPosition) => void;
};

const GoogleMapsContext = createContext<ContextProps>({
  googleMap: null,
  importLibrary: null,
  currentPosition: null,
  setCurrentPosition: () => {}
});

export default GoogleMapsContext;
