import { type NextRequest, NextResponse } from 'next/server';
import { proxyToApi } from '../../../../../../../lib/apiProxy.ts';

const USER_ID = /^\d+$/;

type Params = {
  params: Promise<{ userId: string }>;
};

export async function GET(request: NextRequest, { params }: Params) {
  const { userId } = await params;

  if (!USER_ID.test(userId)) {
    return NextResponse.json({ detail: 'Not found' }, { status: 404 });
  }

  return proxyToApi(request, `/guest/users/${userId}/maps`, {
    signedIn: false
  });
}
