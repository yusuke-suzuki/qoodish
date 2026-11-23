export type ShareLinkData = {
  title: string;
  url: string;
};

export type ShareOutcome = 'shared' | 'copied' | 'cancelled';

export type ShareNavigator = Pick<Navigator, 'clipboard'> &
  Partial<Pick<Navigator, 'share' | 'canShare'>>;

export async function shareLink(
  data: ShareLinkData,
  navigator: ShareNavigator
): Promise<ShareOutcome> {
  if (navigator.share && (navigator.canShare?.(data) ?? true)) {
    try {
      await navigator.share(data);

      return 'shared';
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return 'cancelled';
      }

      throw error;
    }
  }

  await navigator.clipboard.writeText(data.url);

  return 'copied';
}
