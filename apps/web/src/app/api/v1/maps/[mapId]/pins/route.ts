import { type NextRequest, NextResponse } from 'next/server';
import { proxyToApi } from '../../../../../../lib/apiProxy.ts';

const MAP_ID = /^\d+$/;

type Params = {
  params: Promise<{ mapId: string }>;
};

export async function GET(request: NextRequest, { params }: Params) {
  const { mapId } = await params;

  if (!MAP_ID.test(mapId)) {
    return NextResponse.json({ detail: 'Not found' }, { status: 404 });
  }

  return proxyToApi(request, `/maps/${mapId}/pins`, { signedIn: true });
}
