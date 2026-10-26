import type {
  CoauthorshipInvitation,
  CoauthorshipInvitationStatus
} from '../../types/index.ts';
import { apiFetchList } from './api.ts';

export async function getCoauthorshipInvitations(
  lang: string,
  status: Extract<CoauthorshipInvitationStatus, 'pending' | 'accepted'>
): Promise<CoauthorshipInvitation[]> {
  const invitations = await apiFetchList<CoauthorshipInvitation>(
    `/me/coauthorship_invitations?status=${status}`,
    {
      lang,
      next: { revalidate: 0 }
    }
  );

  // An API deployed before the status parameter answers pending invitations
  // whatever is asked, so they must not be listed as accepted.
  return invitations.filter((invitation) => invitation.status === status);
}
