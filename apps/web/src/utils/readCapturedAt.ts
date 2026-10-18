import { capturedAt, readCaptureTags } from './exif.ts';

const EXIF_SEARCH_BYTES = 128 * 1024;

export default async function readCapturedAt(
  file: File
): Promise<number | null> {
  try {
    const tags = readCaptureTags(
      await file.slice(0, EXIF_SEARCH_BYTES).arrayBuffer()
    );

    return tags && capturedAt(tags.dateTime, tags.offset);
  } catch {
    return null;
  }
}
