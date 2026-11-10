import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';
import {
  apiRequests,
  failWith,
  resetServerActionMocks,
  respondWith,
  revalidatedTags
} from '../test/serverActionMocks.ts';

const actions = () => import('./pinProperties.ts');

beforeEach(resetServerActionMocks);

describe('createPinProperty', () => {
  it('defines the property, refreshes the map and returns its id', async () => {
    const { createPinProperty } = await actions();
    respondWith({ id: 5 });

    const result = await createPinProperty(2, {
      name: 'Payment',
      multiple: true,
      icon: '💴',
      color: '#43a047'
    });

    assert.deepEqual(result, { success: true, id: 5 });
    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties',
        method: 'POST',
        body: {
          name: 'Payment',
          multiple: true,
          icon: '💴',
          color: '#43a047'
        }
      }
    ]);
    assert.deepEqual(revalidatedTags(), ['map:2']);
  });

  it('reports the API error without refreshing', async () => {
    const { createPinProperty } = await actions();
    failWith('Name is required', 422);

    assert.deepEqual(
      await createPinProperty(2, {
        name: '',
        multiple: false,
        icon: null,
        color: null
      }),
      {
        success: false,
        error: 'Name is required'
      }
    );
    assert.deepEqual(revalidatedTags(), []);
  });
});

describe('updatePinProperty', () => {
  it('renames the property and refreshes the map', async () => {
    const { updatePinProperty } = await actions();

    const result = await updatePinProperty(2, 5, { name: 'Genre' });

    assert.deepEqual(result, { success: true });
    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties/5',
        method: 'PUT',
        body: { name: 'Genre' }
      }
    ]);
    assert.deepEqual(revalidatedTags(), ['map:2']);
  });

  it('sends only the appearance field that changed', async () => {
    const { updatePinProperty } = await actions();

    await updatePinProperty(2, 5, { color: null });

    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties/5',
        method: 'PUT',
        body: { color: null }
      }
    ]);
  });
});

describe('deletePinProperty', () => {
  it('deletes the property and refreshes the map', async () => {
    const { deletePinProperty } = await actions();

    const result = await deletePinProperty(2, 5);

    assert.deepEqual(result, { success: true });
    assert.deepEqual(apiRequests(), [
      { path: '/maps/2/pin_properties/5', method: 'DELETE', body: undefined }
    ]);
    assert.deepEqual(revalidatedTags(), ['map:2']);
  });

  it('reports the API error without refreshing', async () => {
    const { deletePinProperty } = await actions();
    failWith('Not found', 404);

    assert.deepEqual(await deletePinProperty(2, 5), {
      success: false,
      error: 'Not found'
    });
    assert.deepEqual(revalidatedTags(), []);
  });
});

describe('createPinPropertyOption', () => {
  it('offers the option on the property and refreshes the map', async () => {
    const { createPinPropertyOption } = await actions();

    const result = await createPinPropertyOption(2, 5, { name: 'Cash only' });

    assert.deepEqual(result, { success: true });
    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties/5/options',
        method: 'POST',
        body: { name: 'Cash only' }
      }
    ]);
    assert.deepEqual(revalidatedTags(), ['map:2']);
  });
});

describe('updatePinPropertyOption', () => {
  it('renames the option and refreshes the map', async () => {
    const { updatePinPropertyOption } = await actions();

    const result = await updatePinPropertyOption(2, 5, 8, { name: 'PayPay' });

    assert.deepEqual(result, { success: true });
    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties/5/options/8',
        method: 'PUT',
        body: { name: 'PayPay' }
      }
    ]);
    assert.deepEqual(revalidatedTags(), ['map:2']);
  });

  it('sends only the fields that changed', async () => {
    const { updatePinPropertyOption } = await actions();

    await updatePinPropertyOption(2, 5, 8, { icon: null });

    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties/5/options/8',
        method: 'PUT',
        body: { icon: null }
      }
    ]);
  });
});

describe('deletePinPropertyOption', () => {
  it('deletes the option and refreshes the map', async () => {
    const { deletePinPropertyOption } = await actions();

    const result = await deletePinPropertyOption(2, 5, 8);

    assert.deepEqual(result, { success: true });
    assert.deepEqual(apiRequests(), [
      {
        path: '/maps/2/pin_properties/5/options/8',
        method: 'DELETE',
        body: undefined
      }
    ]);
    assert.deepEqual(revalidatedTags(), ['map:2']);
  });
});
