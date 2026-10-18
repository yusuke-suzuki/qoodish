import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { capturedAt, readCaptureTags } from './exif.ts';

const ASCII = 2;
const LONG = 4;
const IFD_ENTRY_BYTES = 12;

type ExifFields = {
  littleEndian?: boolean;
  dateTime?: string;
  offset?: string;
};

function bytes(...parts: (Uint8Array | number[])[]): Uint8Array<ArrayBuffer> {
  const out = new Uint8Array(parts.reduce((sum, part) => sum + part.length, 0));
  let at = 0;

  for (const part of parts) {
    out.set(part, at);
    at += part.length;
  }

  return out;
}

function text(value: string): number[] {
  return Array.from(value, (char) => char.charCodeAt(0));
}

function segment(marker: number, payload: Uint8Array | number[]): Uint8Array {
  const length = payload.length + 2;
  return bytes([0xff, marker, length >> 8, length & 0xff], payload);
}

function tiff({ littleEndian = true, dateTime, offset }: ExifFields) {
  const strings = (
    [
      [0x9003, dateTime],
      [0x9011, offset]
    ] as const
  ).flatMap(([tag, value]) => (value === undefined ? [] : [{ tag, value }]));

  const ifd0At = 8;
  const exifIfdAt = ifd0At + 2 + IFD_ENTRY_BYTES + 4;
  const dataAt = exifIfdAt + 2 + strings.length * IFD_ENTRY_BYTES + 4;
  const size = strings.reduce(
    (sum, { value }) => sum + value.length + 1,
    dataAt
  );

  const out = new Uint8Array(size);
  const view = new DataView(out.buffer);

  out.set(text(littleEndian ? 'II' : 'MM'));
  view.setUint16(2, 42, littleEndian);
  view.setUint32(4, ifd0At, littleEndian);

  view.setUint16(ifd0At, 1, littleEndian);
  view.setUint16(ifd0At + 2, 0x8769, littleEndian);
  view.setUint16(ifd0At + 4, LONG, littleEndian);
  view.setUint32(ifd0At + 6, 1, littleEndian);
  view.setUint32(ifd0At + 10, exifIfdAt, littleEndian);

  view.setUint16(exifIfdAt, strings.length, littleEndian);
  let valueAt = dataAt;

  strings.forEach(({ tag, value }, index) => {
    const entryAt = exifIfdAt + 2 + index * IFD_ENTRY_BYTES;
    view.setUint16(entryAt, tag, littleEndian);
    view.setUint16(entryAt + 2, ASCII, littleEndian);
    view.setUint32(entryAt + 4, value.length + 1, littleEndian);
    view.setUint32(entryAt + 8, valueAt, littleEndian);
    out.set(text(value), valueAt);
    valueAt += value.length + 1;
  });

  return out;
}

function jpeg(...segments: Uint8Array[]): ArrayBuffer {
  const out = bytes([0xff, 0xd8], ...segments, [0xff, 0xda, 0, 2]);
  return out.buffer;
}

const exif = (fields: ExifFields) =>
  segment(0xe1, bytes(text('Exif\0\0'), tiff(fields)));

const DATE_TIME = '2026:10:17 10:09:44';

describe('readCaptureTags', () => {
  it('reads the capture time and its offset from a little-endian JPEG', () => {
    assert.deepEqual(
      readCaptureTags(jpeg(exif({ dateTime: DATE_TIME, offset: '+09:00' }))),
      { dateTime: DATE_TIME, offset: '+09:00' }
    );
  });

  it('reads a big-endian JPEG', () => {
    assert.deepEqual(
      readCaptureTags(
        jpeg(
          exif({ littleEndian: false, dateTime: DATE_TIME, offset: '-03:30' })
        )
      ),
      { dateTime: DATE_TIME, offset: '-03:30' }
    );
  });

  it('finds the Exif segment behind other application segments', () => {
    const jfif = segment(0xe0, text('JFIF\0\x01\x02'));
    const xmp = segment(0xe1, text('http://ns.adobe.com/xap/1.0/\0<x/>'));

    assert.deepEqual(
      readCaptureTags(jpeg(jfif, xmp, exif({ dateTime: DATE_TIME }))),
      { dateTime: DATE_TIME, offset: null }
    );
  });

  it('reads no capture time when the photo has none', () => {
    assert.deepEqual(readCaptureTags(jpeg(exif({}))), {
      dateTime: null,
      offset: null
    });
  });

  it('reads nothing from a JPEG without Exif', () => {
    assert.equal(readCaptureTags(jpeg(segment(0xe0, text('JFIF\0')))), null);
  });

  it('reads nothing from a file that is not a JPEG', () => {
    assert.equal(
      readCaptureTags(bytes(text('\x89PNG\r\n\x1a\n'), [0, 0, 0, 0]).buffer),
      null
    );
  });

  it('reads nothing from a cut-off Exif segment', () => {
    const whole = new Uint8Array(
      jpeg(exif({ dateTime: DATE_TIME, offset: '+09:00' }))
    );

    assert.equal(readCaptureTags(whole.slice(0, 40).buffer), null);
  });
});

describe('capturedAt', () => {
  it('reads the capture time at the offset the camera recorded', () => {
    assert.equal(
      capturedAt('2026:10:17 10:09:44', '+09:00'),
      Date.parse('2026-10-17T01:09:44Z')
    );
    assert.equal(
      capturedAt('2026:10:17 10:09:44', '-03:30'),
      Date.parse('2026-10-17T13:39:44Z')
    );
  });

  it('reads a capture time without an offset as device local time', () => {
    assert.equal(
      capturedAt('2026:10:17 10:09:44', undefined),
      new Date(2026, 9, 17, 10, 9, 44).getTime()
    );
  });

  it('ignores an offset it cannot read', () => {
    assert.equal(
      capturedAt('2026:10:17 10:09:44', '+9'),
      new Date(2026, 9, 17, 10, 9, 44).getTime()
    );
  });

  it('ignores an offset outside the UTC offsets in use', () => {
    const deviceLocal = new Date(2026, 9, 17, 10, 9, 44).getTime();

    assert.equal(capturedAt('2026:10:17 10:09:44', '+99:99'), deviceLocal);
    assert.equal(capturedAt('2026:10:17 10:09:44', '+14:01'), deviceLocal);
    assert.equal(capturedAt('2026:10:17 10:09:44', '-12:01'), deviceLocal);
    assert.equal(capturedAt('2026:10:17 10:09:44', '+09:60'), deviceLocal);
  });

  it('reads the widest UTC offsets in use', () => {
    assert.equal(
      capturedAt('2026:10:17 10:00:00', '+14:00'),
      Date.parse('2026-10-16T20:00:00Z')
    );
    assert.equal(
      capturedAt('2026:10:17 10:00:00', '-12:00'),
      Date.parse('2026-10-17T22:00:00Z')
    );
  });

  it('rejects a missing or blank capture time', () => {
    assert.equal(capturedAt(undefined, '+09:00'), null);
    assert.equal(capturedAt('0000:00:00 00:00:00', '+09:00'), null);
    assert.equal(capturedAt('    :  :     :  :  ', '+09:00'), null);
  });

  it('rejects a date that does not exist', () => {
    assert.equal(capturedAt('2026:02:30 10:00:00', '+09:00'), null);
    assert.equal(capturedAt('2026:10:17 24:00:00', '+09:00'), null);
  });

  it('reads a year before 100 as that year', () => {
    assert.equal(
      new Date(capturedAt('0050:01:01 00:00:00', '+00:00') ?? 0).toISOString(),
      '0050-01-01T00:00:00.000Z'
    );
  });
});
