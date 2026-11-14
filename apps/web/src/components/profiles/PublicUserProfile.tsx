import {
  CHAPTERS_TAG,
  MAPS_TAG,
  pinListTags,
  userTag
} from '../../lib/cacheTags.ts';
import { getUserChapters } from '../../lib/chapters.ts';
import { cachePublic } from '../../lib/publicCache.ts';
import { getProfile, getPublicUserPins, getUserMaps } from '../../lib/users.ts';
import UserProfile from './UserProfile.tsx';

type Props = {
  userId: string;
  lang: string;
};

export default async function PublicUserProfile({ userId, lang }: Props) {
  'use cache';
  await cachePublic(300, [userTag(userId), MAPS_TAG, CHAPTERS_TAG]);

  const [profile, pins, maps, chapters] = await Promise.all([
    getProfile(userId, lang),
    getPublicUserPins(userId, lang),
    getUserMaps(userId, lang),
    getUserChapters(userId, lang)
  ]);

  if (!profile) {
    return null;
  }

  await cachePublic(300, pinListTags(pins.items));

  return (
    <UserProfile
      profile={profile}
      initialPins={pins.items}
      pinsCursor={pins.nextCursor}
      maps={maps}
      journal={null}
      chapters={chapters}
    />
  );
}
