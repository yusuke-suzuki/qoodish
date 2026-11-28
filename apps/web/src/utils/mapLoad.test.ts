import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  canRetry,
  initialMapLoadState,
  type MapLoadState,
  nextMapLoadState
} from './mapLoad.ts';

const loadFailed: MapLoadState = { failure: 'load', attempt: 2 };
const authFailed: MapLoadState = { failure: 'auth', attempt: 2 };

describe('nextMapLoadState', () => {
  it('records a load failure', () => {
    assert.deepEqual(
      nextMapLoadState(initialMapLoadState, { type: 'loadFailed', attempt: 0 }),
      { failure: 'load', attempt: 0 }
    );
  });

  it('keeps an auth failure when a load fails after it', () => {
    assert.equal(
      nextMapLoadState(authFailed, { type: 'loadFailed', attempt: 2 }),
      authFailed
    );
  });

  it('ignores a load that failed in an earlier attempt', () => {
    const retrying: MapLoadState = { failure: null, attempt: 3 };

    assert.equal(
      nextMapLoadState(retrying, { type: 'loadFailed', attempt: 2 }),
      retrying
    );
  });

  it('replaces a load failure with an auth failure', () => {
    assert.deepEqual(nextMapLoadState(loadFailed, { type: 'authFailed' }), {
      failure: 'auth',
      attempt: 2
    });
  });

  it('clears a load failure and starts the next attempt on retry', () => {
    assert.deepEqual(nextMapLoadState(loadFailed, { type: 'retry' }), {
      failure: null,
      attempt: 3
    });
  });

  it('does not retry an auth failure', () => {
    assert.equal(nextMapLoadState(authFailed, { type: 'retry' }), authFailed);
  });

  it('does not retry when nothing has failed', () => {
    assert.equal(
      nextMapLoadState(initialMapLoadState, { type: 'retry' }),
      initialMapLoadState
    );
  });

  it('retries a load failure once the page is visible and online', () => {
    assert.deepEqual(
      nextMapLoadState(loadFailed, {
        type: 'resumed',
        visible: true,
        online: true
      }),
      { failure: null, attempt: 3 }
    );
  });

  it('waits while the page is hidden', () => {
    assert.equal(
      nextMapLoadState(loadFailed, {
        type: 'resumed',
        visible: false,
        online: true
      }),
      loadFailed
    );
  });

  it('waits while the browser is offline', () => {
    assert.equal(
      nextMapLoadState(loadFailed, {
        type: 'resumed',
        visible: true,
        online: false
      }),
      loadFailed
    );
  });

  it('does not resume an auth failure', () => {
    assert.equal(
      nextMapLoadState(authFailed, {
        type: 'resumed',
        visible: true,
        online: true
      }),
      authFailed
    );
  });
});

describe('canRetry', () => {
  it('offers a retry for a load failure only', () => {
    assert.deepEqual(
      [canRetry('load'), canRetry('auth'), canRetry(null)],
      [true, false, false]
    );
  });
});
