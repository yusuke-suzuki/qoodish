import { createLocalJWKSet, errors, type JSONWebKeySet, jwtVerify } from 'jose';
import describeError from '../utils/describeError.ts';

const SIGNING_KEYS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const DEFAULT_KEYS_TTL_MS = 60 * 60 * 1000;
const MIN_REFETCH_INTERVAL_MS = 60 * 1000;
const FETCH_TIMEOUT_MS = 5000;

type SigningKeys = {
  sequence: number;
  fetchedAt: number;
  expiresAt: number;
  jwks: JSONWebKeySet;
};

// Only a settled key set is shared: Workers settles a promise only in the
// request that created it, so a pending fetch must stay in its own request.
let cached: SigningKeys | undefined;
let fetchSequence = 0;
let lastRotationAt = Number.NEGATIVE_INFINITY;

function maxAgeMs(cacheControl: string | null): number {
  const maxAge = cacheControl?.match(/max-age=(\d+)/)?.[1];
  return maxAge === undefined ? DEFAULT_KEYS_TTL_MS : Number(maxAge) * 1000;
}

function keySetOf(value: unknown): JSONWebKeySet {
  const keys = (value as { keys?: unknown } | null)?.keys;

  if (!Array.isArray(keys) || keys.length === 0) {
    throw new Error('Firebase signing keys answered without a key set');
  }

  try {
    createLocalJWKSet(value as JSONWebKeySet);
  } catch (error) {
    throw new Error(
      `Firebase signing keys answered a malformed key set: ${describeError(error)}`
    );
  }

  return value as JSONWebKeySet;
}

async function fetchSigningKeys(): Promise<JSONWebKeySet> {
  const sequence = ++fetchSequence;
  const startedAt = Date.now();
  const res = await fetch(SIGNING_KEYS_URL, {
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS)
  });

  if (!res.ok) {
    throw new Error(`Firebase signing keys answered ${res.status}`);
  }

  const jwks = keySetOf(await res.json());

  if (!cached || cached.sequence < sequence) {
    cached = {
      sequence,
      fetchedAt: startedAt,
      expiresAt: startedAt + maxAgeMs(res.headers.get('cache-control')),
      jwks
    };
  }

  return cached.jwks;
}

async function signingKeys(): Promise<JSONWebKeySet> {
  if (cached && Date.now() < cached.expiresAt) {
    return cached.jwks;
  }

  try {
    return await fetchSigningKeys();
  } catch (error) {
    if (!cached) {
      throw error;
    }

    console.error(
      `Firebase signing keys unavailable, verifying with the previous set: ${describeError(error)}`
    );
    return cached.jwks;
  }
}

function rotatedKeys(): Promise<JSONWebKeySet> | null {
  const now = Date.now();
  const lastFetch = Math.max(
    lastRotationAt,
    cached?.fetchedAt ?? lastRotationAt
  );

  if (now - lastFetch < MIN_REFETCH_INTERVAL_MS) {
    return null;
  }

  lastRotationAt = now;
  return fetchSigningKeys();
}

async function verify(idToken: string, projectId: string, jwks: JSONWebKeySet) {
  const { payload } = await jwtVerify(idToken, createLocalJWKSet(jwks), {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
    algorithms: ['RS256'],
    requiredClaims: ['exp', 'iat', 'sub']
  });

  return typeof payload.sub === 'string' && payload.sub.length > 0
    ? payload.sub
    : null;
}

export async function verifiedUid(
  idToken: string,
  projectId: string | undefined
): Promise<string | null> {
  if (!projectId) {
    return null;
  }

  try {
    try {
      return await verify(idToken, projectId, await signingKeys());
    } catch (error) {
      const rotated =
        error instanceof errors.JWKSNoMatchingKey ? rotatedKeys() : null;

      if (!rotated) {
        throw error;
      }

      return await verify(idToken, projectId, await rotated);
    }
  } catch (error) {
    if (!(error instanceof errors.JOSEError)) {
      console.error(`Firebase ID token check failed: ${describeError(error)}`);
    }

    return null;
  }
}
