import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { buildApiHeaders, resolveApiLanguage } from './apiRequest.ts';

describe('resolveApiLanguage', () => {
  it('prefers the locale of the page the reader is on', () => {
    assert.equal(
      resolveApiLanguage({
        pageLocale: 'ja',
        rememberedLocale: 'en',
        acceptLanguage: 'en-US'
      }),
      'ja'
    );
  });

  it('falls back to the remembered locale off a localized page', () => {
    assert.equal(
      resolveApiLanguage({ rememberedLocale: 'ja', acceptLanguage: 'en-US' }),
      'ja'
    );
  });

  it('falls back to the preferred supported browser language without either', () => {
    assert.equal(
      resolveApiLanguage({
        pageLocale: null,
        acceptLanguage: 'fr,en-US;q=0.5,ja;q=0.8'
      }),
      'ja'
    );
  });

  it('falls back to English without a supported browser language', () => {
    assert.equal(
      resolveApiLanguage({ pageLocale: null, acceptLanguage: 'fr-FR' }),
      'en'
    );
  });

  it('ignores values that are not supported locales', () => {
    assert.equal(
      resolveApiLanguage({
        pageLocale: 'fr',
        rememberedLocale: 'de',
        acceptLanguage: 'ja'
      }),
      'ja'
    );
  });
});

describe('buildApiHeaders', () => {
  it('omits the authorization header for a guest', () => {
    const headers = buildApiHeaders({ token: null, acceptLanguage: 'en' });

    assert.equal(headers.has('authorization'), false);
    assert.equal(headers.get('accept'), 'application/json');
    assert.equal(headers.get('accept-language'), 'en');
    assert.equal(headers.get('content-type'), 'application/json');
  });

  it('carries the bearer token of a signed-in reader', () => {
    const headers = buildApiHeaders({ token: 'abc', acceptLanguage: 'ja' });

    assert.equal(headers.get('authorization'), 'Bearer abc');
    assert.equal(headers.get('accept-language'), 'ja');
  });

  it('lets a caller header replace the default of any casing', () => {
    const headers = buildApiHeaders({
      token: null,
      acceptLanguage: 'en',
      headers: { 'content-type': 'multipart/form-data' }
    });

    assert.equal(headers.get('content-type'), 'multipart/form-data');
  });
});
