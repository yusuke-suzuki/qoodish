import type { NextRequest } from 'next/server';
import { proxyToApi } from '../../../../../lib/apiProxy.ts';

export function GET(request: NextRequest) {
  return proxyToApi(request, '/v2/maps', { signedIn: true });
}
