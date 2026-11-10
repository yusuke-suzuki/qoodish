import type { ReactNode } from 'react';
import type {
  CursorPage,
  Notification,
  Profile
} from '../../../types/index.ts';
import AuthProvider from '../../components/auth/AuthProvider.tsx';
import PushSubscriptionSync from '../../components/auth/PushSubscriptionSync.tsx';
import TermsRevisionNotice from '../../components/legal/TermsRevisionNotice.tsx';
import { getServerAuthState } from '../../lib/auth.ts';
import { getMyProfile, getNotifications } from '../../lib/users.ts';
import { pendingTermsRevision } from '../../utils/getLegalDocument.ts';
import AccountProviders from './AccountProviders.tsx';

type Props = {
  children: ReactNode;
  lang: string;
};

export default async function SessionProviders({ children, lang }: Props) {
  const { authenticated, pending, uid, token } = await getServerAuthState();
  const profilePromise = authenticated
    ? getMyProfile(lang, token)
    : Promise.resolve<Profile | null>(null);
  // The bell is chrome, drawn above every error boundary: an outage there
  // must cost the unread count, not the page.
  const noNotifications: CursorPage<Notification> = {
    items: [],
    nextCursor: null
  };
  const unreadNotificationsPromise = authenticated
    ? getNotifications(lang, { read: false }).catch(() => noNotifications)
    : Promise.resolve(noNotifications);

  return (
    <AuthProvider
      serverAuthenticated={authenticated}
      serverPending={pending}
      serverUid={uid ?? null}
    >
      <AccountProviders
        profilePromise={profilePromise}
        unreadNotificationsPromise={unreadNotificationsPromise}
      >
        <PushSubscriptionSync />
        <TermsRevisionNotice effectiveOn={pendingTermsRevision()} />
        {children}
      </AccountProviders>
    </AuthProvider>
  );
}
