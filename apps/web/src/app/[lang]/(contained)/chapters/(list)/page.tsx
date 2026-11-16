import type { Metadata } from 'next';
import ChapterFeed from '../../../../../components/chapters/ChapterFeed.tsx';
import PageHeader from '../../../../../components/common/PageHeader.tsx';
import { getChapterFeed } from '../../../../../lib/chapters.ts';
import { getDictionary } from '../../../../../utils/getDictionary.ts';
import { localePath } from '../../../../../utils/locales.ts';
import {
  buildAlternates,
  defaultOgImage,
  ogImages
} from '../../../../../utils/metadata.ts';

type Props = {
  params: Promise<{ lang: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { lang } = await params;
  const dict = getDictionary(lang);
  const title = `${dict['recent chapters']} | Qoodish`;
  const description = dict['meta description'];

  return {
    title,
    description,
    alternates: buildAlternates(lang, '/chapters'),
    openGraph: {
      type: 'website',
      title,
      description,
      url: localePath(lang, '/chapters'),
      images: ogImages(defaultOgImage(lang), title),
      locale: lang === 'en' ? 'en_US' : 'ja_JP',
      siteName: dict['meta headline']
    },
    twitter: {
      card: 'summary_large_image'
    }
  };
}

export default async function ChaptersPage({ params }: Props) {
  const { lang } = await params;
  const dict = getDictionary(lang);
  const { items, nextCursor } = await getChapterFeed(lang);

  return (
    <>
      <PageHeader title={dict['recent chapters']} />

      <ChapterFeed initialChapters={items} nextCursor={nextCursor} />
    </>
  );
}
