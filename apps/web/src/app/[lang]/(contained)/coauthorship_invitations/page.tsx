import type { Metadata } from 'next';
import SignInRequired from '../../../../components/auth/SignInRequired.tsx';
import CoauthorshipInvitationsView from '../../../../components/coauthors/CoauthorshipInvitationsView.tsx';
import PageHeader from '../../../../components/common/PageHeader.tsx';
import { getServerAuthState } from '../../../../lib/auth.ts';
import { getCoauthorshipInvitations } from '../../../../lib/coauthorshipInvitations.ts';
import { getDictionary } from '../../../../utils/getDictionary.ts';
import { buildAlternates } from '../../../../utils/metadata.ts';

type Props = {
  params: Promise<{ lang: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { lang } = await params;
  const dict = getDictionary(lang);
  const title = `${dict.invites} | Qoodish`;
  const description = dict['meta description'];

  return {
    title,
    description,
    robots: 'noindex',
    alternates: buildAlternates(lang, '/coauthorship_invitations')
  };
}

export default async function InvitationsPage({ params }: Props) {
  const { lang } = await params;
  const { authenticated } = await getServerAuthState();

  if (!authenticated) {
    return <SignInRequired title={getDictionary(lang).invites} />;
  }

  const [pending, accepted] = await Promise.all([
    getCoauthorshipInvitations(lang, 'pending'),
    getCoauthorshipInvitations(lang, 'accepted')
  ]);

  return (
    <>
      <PageHeader title={getDictionary(lang).invites} />
      <CoauthorshipInvitationsView pending={pending} accepted={accepted} />
    </>
  );
}
