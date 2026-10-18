export default async function fetchApiList<T>(
  path: string,
  signal?: AbortSignal
): Promise<T[]> {
  const res = await fetch(`/api/v1/${path}`, { signal });

  if (!res.ok) {
    throw new Error(`Fetching ${path} failed with status ${res.status}`);
  }

  return (await res.json()) as T[];
}
