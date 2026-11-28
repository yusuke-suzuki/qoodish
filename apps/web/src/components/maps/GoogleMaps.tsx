import { importLibrary, setOptions } from '@googlemaps/js-api-loader';
import {
  Box,
  Button,
  Stack,
  type SxProps,
  Typography,
  useColorScheme,
  useMediaQuery,
  useTheme
} from '@mui/material';
import { useParams } from 'next/navigation';
import {
  Fragment,
  type ReactNode,
  useCallback,
  useEffect,
  useEffectEvent,
  useRef,
  useState
} from 'react';
import GoogleMapsContext, {
  type LoadLibrary
} from '../../context/GoogleMapsContext.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import { toLocale } from '../../utils/locales.ts';
import reportClientError from '../../utils/reportClientError.ts';

declare global {
  interface Window {
    gm_authFailure?: () => void;
  }
}

// The Maps script carries its language in the URL it is loaded from, and
// setOptions applies only once per document, so the first map settles the
// language for every later one; a full load picks a new language up.
let optionsSet = false;

function configureMaps(language: string): void {
  if (optionsSet) {
    return;
  }

  setOptions({
    key: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ?? '',
    v: 'beta',
    language
  });
  optionsSet = true;
}

type Failure = 'load' | 'auth';

type Props = {
  mapId: string | undefined;
  children?: ReactNode;
  sx: SxProps;
  mapOptions?: Partial<google.maps.MapOptions>;
  center?: google.maps.LatLngLiteral | null;
  zoom?: number;
  position?: GeolocationPosition | null;
};

function GoogleMaps({
  mapId,
  children,
  sx,
  mapOptions,
  center,
  zoom,
  position
}: Props) {
  const mapRef = useRef<HTMLDivElement>(null);
  const { lang } = useParams<{ lang: string }>();
  const dictionary = useDictionary();

  const [googleMap, setGoogleMap] = useState<google.maps.Map | null>(null);
  const [currentPosition, setCurrentPosition] =
    useState<GeolocationPosition | null>(position ?? null);
  const [prevPosition, setPrevPosition] = useState(position);

  if (position !== prevPosition) {
    setPrevPosition(position);

    if (position) {
      setCurrentPosition(position);
    }
  }

  const language = toLocale(lang);

  const theme = useTheme();
  const mdUp = useMediaQuery(theme.breakpoints.up('md'));

  // The Maps API takes a color scheme only when a map is constructed, so a
  // change of theme builds the map again, in a fresh element, from the
  // camera the old one stood at.
  const { colorScheme } = useColorScheme();
  const [builtScheme, setBuiltScheme] = useState<'light' | 'dark' | null>(null);
  const [generation, setGeneration] = useState(0);
  const [carriedCamera, setCarriedCamera] =
    useState<google.maps.CameraOptions | null>(null);

  if (googleMap && colorScheme && builtScheme && colorScheme !== builtScheme) {
    setCarriedCamera({
      center: googleMap.getCenter()?.toJSON(),
      zoom: googleMap.getZoom(),
      heading: googleMap.getHeading(),
      tilt: googleMap.getTilt()
    });
    setBuiltScheme(null);
    setGoogleMap(null);
    setGeneration((current) => current + 1);
  }

  const [failure, setFailure] = useState<Failure | null>(null);
  const [attempt, setAttempt] = useState(0);

  // Applied once per value rather than once per map, so that a map rebuilt
  // for a new theme keeps the camera it carried over instead of jumping back.
  const appliedCenterRef = useRef<string | null>(null);
  const appliedZoomRef = useRef<number | null>(null);

  // A failed library leaves the map without the parts drawn from it, so the
  // map is dropped for the failure notice and built again, with the children
  // that draw on it, on retry.
  const loadLibrary: LoadLibrary = useCallback(
    async (name) => {
      configureMaps(language);

      try {
        return await importLibrary(name);
      } catch {
        setFailure((current) => current ?? 'load');
        setBuiltScheme(null);
        setGoogleMap(null);
        setGeneration((current) => current + 1);
        appliedCenterRef.current = null;
        appliedZoomRef.current = null;
        return null;
      }
    },
    [language]
  );

  const initGoogleMaps = useCallback(async () => {
    if (!mapRef.current) {
      return;
    }

    const [mapsLibrary, coreLibrary] = await Promise.all([
      loadLibrary('maps'),
      loadLibrary('core')
    ]);

    if (!mapsLibrary || !coreLibrary || !mapRef.current) {
      return;
    }

    const { Map: GoogleMap } = mapsLibrary;
    const { ColorScheme, ControlPosition } = coreLibrary;

    // The scheme the reader chose, which may differ from the system's, so
    // ColorScheme.FOLLOW_SYSTEM would not do. useColorScheme reports nothing
    // until the provider has mounted, but InitColorSchemeScript has put the
    // class on the root by then.
    const dark =
      (colorScheme ??
        (document.documentElement.classList.contains('dark')
          ? 'dark'
          : 'light')) === 'dark';

    const map = new GoogleMap(mapRef.current, {
      colorScheme: dark ? ColorScheme.DARK : ColorScheme.LIGHT,
      zoom: 17,
      ...carriedCamera,
      zoomControl: !!mdUp,
      zoomControlOptions: {
        position: ControlPosition.LEFT_BOTTOM
      },
      streetViewControl: true,
      streetViewControlOptions: {
        position: ControlPosition.LEFT_BOTTOM
      },
      scaleControl: false,
      mapTypeControl: false,
      fullscreenControl: false,
      gestureHandling: 'greedy',
      mapId: mapId,
      ...mapOptions
    });

    setCarriedCamera(null);
    setBuiltScheme(dark ? 'dark' : 'light');
    setGoogleMap(map);
  }, [mapId, mapOptions, mdUp, loadLibrary, carriedCamera, colorScheme]);

  useEffect(() => {
    if (googleMap || failure || !mapRef.current) {
      return;
    }

    initGoogleMaps().catch(() => setFailure((current) => current ?? 'load'));
  }, [googleMap, failure, initGoogleMaps]);

  const retry = () => {
    setFailure(null);
    setAttempt((current) => current + 1);
  };

  const onAuthFailure = useEffectEvent(() => {
    reportClientError(
      new Error('Google Maps rejected the API key'),
      'google-maps-auth'
    );
    setFailure('auth');
    setBuiltScheme(null);
    setGoogleMap(null);
    setGeneration((current) => current + 1);
  });

  useEffect(() => {
    const handleAuthFailure = () => onAuthFailure();
    window.gm_authFailure = handleAuthFailure;

    return () => {
      if (window.gm_authFailure === handleAuthFailure) {
        window.gm_authFailure = undefined;
      }
    };
  }, []);

  useEffect(() => {
    if (failure !== 'load') {
      return;
    }

    const retryWhenVisible = () => {
      if (document.visibilityState === 'visible' && navigator.onLine) {
        setFailure(null);
        setAttempt((current) => current + 1);
      }
    };

    window.addEventListener('online', retryWhenVisible);
    document.addEventListener('visibilitychange', retryWhenVisible);

    return () => {
      window.removeEventListener('online', retryWhenVisible);
      document.removeEventListener('visibilitychange', retryWhenVisible);
    };
  }, [failure]);

  useEffect(() => {
    if (!('geolocation' in navigator) || !('permissions' in navigator)) {
      return;
    }

    let cancelled = false;

    const restoreCurrentPosition = async () => {
      let status: PermissionStatus;

      try {
        status = await navigator.permissions.query({ name: 'geolocation' });
      } catch {
        // Safari below 16 rejects the geolocation query; without a readable
        // permission state, getCurrentPosition could raise the browser prompt.
        return;
      }

      if (cancelled || status.state !== 'granted') {
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          if (!cancelled) {
            setCurrentPosition(position);
          }
        },
        () => {},
        {
          enableHighAccuracy: false,
          maximumAge: 30000,
          timeout: 10000
        }
      );
    };

    restoreCurrentPosition();

    return () => {
      cancelled = true;
    };
  }, []);

  const centerLat = center?.lat;
  const centerLng = center?.lng;

  useEffect(() => {
    if (!googleMap || centerLat === undefined || centerLng === undefined) {
      return;
    }

    const key = `${centerLat},${centerLng}`;

    if (appliedCenterRef.current !== key) {
      appliedCenterRef.current = key;
      googleMap.panTo({ lat: centerLat, lng: centerLng });
    }
  }, [googleMap, centerLat, centerLng]);

  useEffect(() => {
    if (googleMap && zoom && appliedZoomRef.current !== zoom) {
      appliedZoomRef.current = zoom;
      googleMap.setZoom(zoom);
    }
  }, [googleMap, zoom]);

  const contextValue = {
    googleMap,
    loadLibrary,
    currentPosition,
    setCurrentPosition
  };

  return (
    <Box>
      <Box key={generation} ref={mapRef} sx={sx}>
        {failure && (
          <Stack
            spacing={2}
            sx={{
              height: '100%',
              alignItems: 'center',
              justifyContent: 'center',
              p: 2,
              textAlign: 'center'
            }}
          >
            <Typography variant="body2" color="text.secondary">
              {failure === 'auth'
                ? dictionary['map unavailable']
                : dictionary['map could not load']}
            </Typography>
            {failure === 'load' && (
              <Button variant="outlined" onClick={retry}>
                {dictionary.retry}
              </Button>
            )}
          </Stack>
        )}
      </Box>

      <GoogleMapsContext.Provider value={contextValue}>
        <Fragment key={attempt}>{children}</Fragment>
      </GoogleMapsContext.Provider>
    </Box>
  );
}

export default GoogleMaps;
