import { ButtonBase, Card, CardMedia, Skeleton } from '@mui/material';

type Props = {
  position: google.maps.LatLngLiteral | null;
  width: number;
  height: number;
};

const NIGHT_MODE_STYLES = [
  'element:geometry|color:0x242f3e',
  'element:labels.text.stroke|color:0x242f3e',
  'element:labels.text.fill|color:0x746855',
  'feature:administrative.locality|element:labels.text.fill|color:0xd59563',
  'feature:poi|element:labels.text.fill|color:0xd59563',
  'feature:poi.park|element:geometry|color:0x263c3f',
  'feature:poi.park|element:labels.text.fill|color:0x6b9a76',
  'feature:road|element:geometry|color:0x38414e',
  'feature:road|element:geometry.stroke|color:0x212a37',
  'feature:road|element:labels.text.fill|color:0x9ca5b3',
  'feature:road.highway|element:geometry|color:0x746855',
  'feature:road.highway|element:geometry.stroke|color:0x1f2835',
  'feature:road.highway|element:labels.text.fill|color:0xf3d19c',
  'feature:transit|element:geometry|color:0x2f3948',
  'feature:transit.station|element:labels.text.fill|color:0xd59563',
  'feature:water|element:geometry|color:0x17263c',
  'feature:water|element:labels.text.fill|color:0x515c6d',
  'feature:water|element:labels.text.stroke|color:0x17263c'
];

function staticMapUrl(
  { lat, lng }: google.maps.LatLngLiteral,
  width: number,
  height: number,
  styles: string[] = []
): string {
  const url = new URL('https://maps.googleapis.com/maps/api/staticmap');
  url.searchParams.set('center', `${lat},${lng}`);
  url.searchParams.set('markers', `color:red|${lat},${lng}`);
  url.searchParams.set('zoom', '15');
  url.searchParams.set('size', `${width}x${height}`);
  url.searchParams.set('scale', '2');
  url.searchParams.set(
    'key',
    process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ?? ''
  );

  for (const style of styles) {
    url.searchParams.append('style', style);
  }

  return url.toString();
}

const imageSx = {
  display: 'block',
  objectFit: 'cover',
  width: '100%',
  height: '100%'
} as const;

function StaticMap({ position, width, height }: Props) {
  if (!position) {
    return <Skeleton variant="rectangular" width={width} height={height} />;
  }

  return (
    <Card>
      <ButtonBase
        component="a"
        href={`https://www.google.com/maps/search/?api=1&query=${position.lat},${position.lng}`}
        target="_blank"
        rel="noreferrer"
      >
        {/* Both images are rendered and CSS shows the one for the current
            scheme: a <picture> source can only follow the system setting,
            not the reader's choice. A lazy image that is not displayed is
            never fetched. */}
        <CardMedia
          component="img"
          image={staticMapUrl(position, width, height)}
          width={width}
          height={height}
          loading="lazy"
          sx={(theme) => ({
            ...imageSx,
            ...theme.applyStyles('dark', { display: 'none' })
          })}
        />
        <CardMedia
          component="img"
          image={staticMapUrl(position, width, height, NIGHT_MODE_STYLES)}
          width={width}
          height={height}
          loading="lazy"
          sx={(theme) => ({
            ...imageSx,
            display: 'none',
            ...theme.applyStyles('dark', { display: 'block' })
          })}
        />
      </ButtonBase>
    </Card>
  );
}

export default StaticMap;
