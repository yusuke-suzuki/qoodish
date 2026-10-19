import type { NextRequest } from 'next/server';
import { proxyToApi } from '../../../../../lib/apiProxy.ts';

export function GET(request: NextRequest) {
  return proxyToApi(request, '/guest/pins', { signedIn: false });
}
