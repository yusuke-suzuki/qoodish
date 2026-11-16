import type { Metadata } from 'next';
import PageHeader from '../../../../../components/common/PageHeader.tsx';
import PinFeed from '../../../../../components/pins/PinFeed.tsx';
import { getPinFeed } from '../../../../../lib/pins.ts';
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
  const title = `${dict['recent pins']} | Qoodish`;
  const description = dict['meta description'];

  return {
    title,
    description,
    alternates: buildAlternates(lang, '/pins'),
    openGraph: {
      type: 'website',
      title,
      description,
      url: localePath(lang, '/pins'),
      images: ogImages(defaultOgImage(lang), title),
      locale: lang === 'en' ? 'en_US' : 'ja_JP',
      siteName: dict['meta headline']
    },
    twitter: {
      card: 'summary_large_image'
    }
  };
}

export default async function PinsPage({ params }: Props) {
  const { lang } = await params;
  const dict = getDictionary(lang);
  const { items, nextCursor } = await getPinFeed(lang);

  return (
    <>
      <PageHeader title={dict['recent pins']} />

      <PinFeed initialPins={items} nextCursor={nextCursor} />
    </>
  );
}
