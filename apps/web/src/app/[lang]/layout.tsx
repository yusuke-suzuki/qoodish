import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import type { Metadata, Viewport } from 'next';
import { notFound } from 'next/navigation';
import type { ReactNode } from 'react';
import JsonLd from '../../components/common/JsonLd.tsx';
import MaintenanceStatus from '../../components/common/MaintenanceStatus.tsx';
import Shell from '../../components/layouts/Shell.tsx';
import ShellProvider from '../../components/layouts/ShellProvider.tsx';
import { THEME_COLOR } from '../../utils/brand.ts';
import { getDictionary } from '../../utils/getDictionary.ts';
import { isLocale, LOCALES } from '../../utils/locales.ts';
import { defaultOgImage, ogImages, SITE_ORIGIN } from '../../utils/metadata.ts';
import { siteStructuredData } from '../../utils/structuredData.ts';
import { fontVariables } from '../fonts.ts';
import Providers from './Providers.tsx';
import SessionProviders from './SessionProviders.tsx';

type Props = {
  children: ReactNode;
  params: Promise<{ lang: string }>;
};

export function generateStaticParams() {
  return LOCALES.map((lang) => ({ lang }));
}

export const viewport: Viewport = {
  themeColor: THEME_COLOR,
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',
  // Shrink the layout viewport with the software keyboard. Under the default
  // resizes-visual, fixed-positioned dialogs and app bars get pushed behind it.
  interactiveWidget: 'resizes-content'
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { lang } = await params;
  const dict = getDictionary(lang);
  const defaultThumbnailUrl = defaultOgImage(lang);

  return {
    metadataBase: new URL(SITE_ORIGIN),
    title: 'Qoodish',
    description: dict['meta description'],
    robots: process.env.APP_ENV !== 'production' ? 'noindex' : undefined,
    icons: {
      icon: [
        { url: '/icons/icon_x32.png', sizes: '32x32', type: 'image/png' },
        { url: '/icons/icon_x16.png', sizes: '16x16', type: 'image/png' }
      ],
      apple: [
        { url: '/icons/icon_x180.png' },
        { url: '/icons/icon_x152.png', sizes: '152x152' },
        { url: '/icons/icon_x180.png', sizes: '180x180' },
        { url: '/icons/icon_x167.png', sizes: '167x167' }
      ]
    },
    appleWebApp: {
      capable: true,
      title: 'Qoodish',
      statusBarStyle: 'black-translucent'
    },
    openGraph: {
      type: 'website',
      title: 'Qoodish',
      description: dict['meta description'],
      siteName: 'Qoodish',
      images: ogImages(defaultThumbnailUrl, dict['meta headline']),
      locale: lang === 'en' ? 'en_US' : 'ja_JP'
    },
    twitter: {
      card: 'summary_large_image'
    },
    // `other` renders <meta name="...">, which Open Graph parsers ignore.
    other: {
      'twitter:domain': 'qoodish.com',
      'mobile-web-app-capable': 'yes'
    }
  };
}

export default async function RootLayout({ children, params }: Props) {
  const { lang } = await params;

  if (!isLocale(lang)) {
    notFound();
  }

  const dict = getDictionary(lang);

  return (
    // InitColorSchemeScript adds the color scheme class before hydration.
    <html lang={lang} className={fontVariables} suppressHydrationWarning>
      <head>
        <link href="https://www.googleapis.com" rel="preconnect dns-prefetch" />
        <link
          href="https://storage.cloud.google.com"
          rel="preconnect dns-prefetch"
        />
        <link
          href="https://storage.googleapis.com"
          rel="preconnect dns-prefetch"
        />
        <JsonLd
          data={siteStructuredData(
            lang,
            dict['meta headline'],
            dict['meta description']
          )}
        />
      </head>
      <body>
        <InitColorSchemeScript attribute="class" />
        <Providers lang={lang} dictionary={dict}>
          <SessionProviders lang={lang}>
            <ShellProvider>
              <Shell>{children}</Shell>
            </ShellProvider>
          </SessionProviders>
          <MaintenanceStatus lang={lang} />
        </Providers>
      </body>
    </html>
  );
}
