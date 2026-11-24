import { useEffect } from 'react';

const LAST_RELOAD_KEY = 'stale-chunk-reload-at';
const MIN_RELOAD_INTERVAL_MS = 10_000;

function markReload(): boolean {
  try {
    const last = Number(sessionStorage.getItem(LAST_RELOAD_KEY));

    if (Date.now() - last < MIN_RELOAD_INTERVAL_MS) {
      return false;
    }

    sessionStorage.setItem(LAST_RELOAD_KEY, String(Date.now()));
    return true;
  } catch {
    return false;
  }
}

export default function useReloadOnStaleChunk() {
  useEffect(() => {
    const reloadForNewDeploy = (event: Event) => {
      if (!navigator.onLine || !markReload()) {
        return;
      }

      event.preventDefault();
      window.location.reload();
    };

    window.addEventListener('vite:preloadError', reloadForNewDeploy);

    return () => {
      window.removeEventListener('vite:preloadError', reloadForNewDeploy);
    };
  }, []);
}
