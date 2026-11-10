import type { MetadataRoute } from 'next';
import { connection } from 'next/server';
import { SITE_ORIGIN } from '../utils/metadata.ts';

// Only production is open to crawlers; a preview or dev deployment serving
// the same allow-all would be indexed as a duplicate of the real site.
export default async function robots(): Promise<MetadataRoute.Robots> {
  // APP_ENV is a Workers runtime binding, not a build variable, so the route
  // must be evaluated per request rather than baked in at build time.
  await connection();

  if (process.env.APP_ENV !== 'production') {
    return {
      rules: { userAgent: '*', disallow: '/' }
    };
  }

  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: `${SITE_ORIGIN}/sitemap.xml`
  };
}
