// Imported lazily for the same reason as next/headers in apiRequest.ts.
export async function cachePublic(
  revalidate: number,
  tags: string[]
): Promise<void> {
  const { cacheLife, cacheTag } = await import('next/cache');
  cacheLife({ revalidate });
  cacheTag(...tags);
}
