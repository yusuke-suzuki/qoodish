import { cookies } from 'next/headers';
import { cache } from 'react';
import { verifiedUid } from './firebaseIdToken.ts';
import { REFRESH_TOKEN_COOKIE, SESSION_COOKIE } from './session.ts';

type ServerAuthState = {
  authenticated: boolean;
  pending: boolean;
  uid?: string;
  token?: string;
};

function resolveUid(idToken: string): Promise<string | null> {
  return verifiedUid(idToken, process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID);
}

export async function verifyIdToken(idToken: string): Promise<boolean> {
  return (await resolveUid(idToken)) !== null;
}

export const getServerAuthState = cache(async (): Promise<ServerAuthState> => {
  const cookieStore = await cookies();
  const idToken = cookieStore.get(SESSION_COOKIE)?.value;
  const pending = cookieStore.has(REFRESH_TOKEN_COOKIE);

  if (!idToken) {
    return { authenticated: false, pending };
  }

  const uid = await resolveUid(idToken);

  if (uid) {
    return { authenticated: true, pending: false, uid, token: idToken };
  }

  return { authenticated: false, pending };
});
