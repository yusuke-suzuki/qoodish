export function toDatetimeLocal(value: string | Date): string {
  const date = new Date(value);
  const pad = (part: number) => String(part).padStart(2, '0');

  return `${String(date.getFullYear()).padStart(4, '0')}-${pad(
    date.getMonth() + 1
  )}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function isPastPeriod(
  startedAt: string,
  finishedAt: string,
  now: string
): boolean {
  return (
    Boolean(startedAt && finishedAt) &&
    startedAt < finishedAt &&
    finishedAt <= now
  );
}
