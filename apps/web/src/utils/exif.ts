const JPEG_START = 0xffd8;
const START_OF_SCAN = 0xffda;
const MARKER_PREFIX = 0xff00;
const APP1 = 0xffe1;
const EXIF_HEADER = 'Exif\0\0';
const LITTLE_ENDIAN = 0x4949;
const BIG_ENDIAN = 0x4d4d;
const TIFF_MAGIC = 42;
const IFD_ENTRY_BYTES = 12;
const INLINE_VALUE_BYTES = 4;
const ASCII = 2;
const EXIF_IFD_POINTER = 0x8769;
const DATE_TIME_ORIGINAL = 0x9003;
const OFFSET_TIME_ORIGINAL = 0x9011;
const EXIF_DATE_TIME = /^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
const EXIF_OFFSET = /^([+-])(\d{2}):(\d{2})$/;
const EARLIEST_OFFSET_MINUTES = -12 * 60;
const LATEST_OFFSET_MINUTES = 14 * 60;
const MINUTE_MS = 60 * 1000;

export type CaptureTags = {
  dateTime: string | null;
  offset: string | null;
};

const latin1 = new TextDecoder('latin1');

function readText(view: DataView, at: number, length: number): string {
  return latin1.decode(
    new Uint8Array(view.buffer, view.byteOffset + at, length)
  );
}

function findTiffStart(view: DataView): number | null {
  if (view.getUint16(0) !== JPEG_START) {
    return null;
  }

  let at = 2;

  while (at + 4 <= view.byteLength) {
    const marker = view.getUint16(at);

    if (
      marker === START_OF_SCAN ||
      (marker & MARKER_PREFIX) !== MARKER_PREFIX
    ) {
      return null;
    }

    const headerAt = at + 4;

    if (
      marker === APP1 &&
      readText(view, headerAt, EXIF_HEADER.length) === EXIF_HEADER
    ) {
      return headerAt + EXIF_HEADER.length;
    }

    at += 2 + view.getUint16(at + 2);
  }

  return null;
}

function ifdEntries(
  view: DataView,
  tiffStart: number,
  ifdOffset: number,
  littleEndian: boolean
): Map<number, number> {
  const ifdAt = tiffStart + ifdOffset;
  const count = view.getUint16(ifdAt, littleEndian);
  const entries = new Map<number, number>();

  for (let index = 0; index < count; index += 1) {
    const entryAt = ifdAt + 2 + index * IFD_ENTRY_BYTES;
    entries.set(view.getUint16(entryAt, littleEndian), entryAt);
  }

  return entries;
}

function asciiValue(
  view: DataView,
  tiffStart: number,
  entryAt: number | undefined,
  littleEndian: boolean
): string | null {
  if (
    entryAt === undefined ||
    view.getUint16(entryAt + 2, littleEndian) !== ASCII
  ) {
    return null;
  }

  const length = view.getUint32(entryAt + 4, littleEndian);
  const valueAt =
    length <= INLINE_VALUE_BYTES
      ? entryAt + 8
      : tiffStart + view.getUint32(entryAt + 8, littleEndian);

  return readText(view, valueAt, length).replace(/\0+$/, '');
}

export function readCaptureTags(buffer: ArrayBuffer): CaptureTags | null {
  try {
    const view = new DataView(buffer);
    const tiffStart = findTiffStart(view);

    if (tiffStart === null) {
      return null;
    }

    const byteOrder = view.getUint16(tiffStart);

    if (byteOrder !== LITTLE_ENDIAN && byteOrder !== BIG_ENDIAN) {
      return null;
    }

    const littleEndian = byteOrder === LITTLE_ENDIAN;

    if (view.getUint16(tiffStart + 2, littleEndian) !== TIFF_MAGIC) {
      return null;
    }

    const ifd0 = ifdEntries(
      view,
      tiffStart,
      view.getUint32(tiffStart + 4, littleEndian),
      littleEndian
    );
    const pointerAt = ifd0.get(EXIF_IFD_POINTER);

    if (pointerAt === undefined) {
      return null;
    }

    const exifIfd = ifdEntries(
      view,
      tiffStart,
      view.getUint32(pointerAt + 8, littleEndian),
      littleEndian
    );

    return {
      dateTime: asciiValue(
        view,
        tiffStart,
        exifIfd.get(DATE_TIME_ORIGINAL),
        littleEndian
      ),
      offset: asciiValue(
        view,
        tiffStart,
        exifIfd.get(OFFSET_TIME_ORIGINAL),
        littleEndian
      )
    };
  } catch (error) {
    if (error instanceof RangeError) {
      return null;
    }

    throw error;
  }
}

function offsetMinutes(offset: unknown): number | null {
  const match = typeof offset === 'string' ? EXIF_OFFSET.exec(offset) : null;

  if (!match || Number(match[3]) >= 60) {
    return null;
  }

  const magnitude = Number(match[2]) * 60 + Number(match[3]);
  const minutes = match[1] === '-' ? -magnitude : magnitude;

  return minutes >= EARLIEST_OFFSET_MINUTES && minutes <= LATEST_OFFSET_MINUTES
    ? minutes
    : null;
}

export function capturedAt(dateTime: unknown, offset: unknown): number | null {
  const match =
    typeof dateTime === 'string' ? EXIF_DATE_TIME.exec(dateTime) : null;

  if (!match) {
    return null;
  }

  const [year, month, day, hour, minute, second] = match.slice(1).map(Number);
  const zone = offsetMinutes(offset);

  const local = new Date(Date.UTC(year, month - 1, day, hour, minute, second));
  local.setUTCFullYear(year);

  const fieldsHold =
    local.getUTCFullYear() === year &&
    local.getUTCMonth() === month - 1 &&
    local.getUTCDate() === day &&
    local.getUTCHours() === hour &&
    local.getUTCMinutes() === minute &&
    local.getUTCSeconds() === second;

  if (!fieldsHold || year === 0) {
    return null;
  }

  if (zone !== null) {
    return local.getTime() - zone * MINUTE_MS;
  }

  const deviceLocal = new Date(year, month - 1, day, hour, minute, second);
  deviceLocal.setFullYear(year);
  return deviceLocal.getTime();
}
