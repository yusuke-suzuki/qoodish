import { getCloudflareContext } from '@opennextjs/cloudflare';
import type { NextRequest } from 'next/server';
import { proxyToApi } from '../../../../lib/apiProxy.ts';
import { getServerAuthState } from '../../../../lib/auth.ts';

// The file itself goes straight to Cloudflare Images, so the only thing this
// route can meter is how often one account asks for somewhere to put one.
async function imageUploadAllowed(): Promise<boolean> {
  const { uid } = await getServerAuthState();

  if (!uid) {
    return false;
  }

  const { IMAGE_UPLOAD_BURST_LIMIT, IMAGE_UPLOAD_LIMIT } =
    getCloudflareContext().env;

  for (const limiter of [IMAGE_UPLOAD_BURST_LIMIT, IMAGE_UPLOAD_LIMIT]) {
    if (limiter && !(await limiter.limit({ key: uid })).success) {
      return false;
    }
  }

  return true;
}

export function POST(request: NextRequest) {
  return proxyToApi(request, '/images', {
    signedIn: true,
    withinRateLimit: imageUploadAllowed
  });
}
