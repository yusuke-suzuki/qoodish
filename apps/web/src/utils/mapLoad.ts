export type MapFailure = 'load' | 'build' | 'auth';

export type MapLoadState = {
  failure: MapFailure | null;
  attempt: number;
};

export type MapLoadEvent =
  | { type: 'loadFailed'; attempt: number }
  | { type: 'buildFailed' }
  | { type: 'authFailed' }
  | { type: 'retry' }
  | { type: 'resumed'; visible: boolean; online: boolean };

export const initialMapLoadState: MapLoadState = { failure: null, attempt: 0 };

export function canRetry(failure: MapFailure | null): boolean {
  return failure === 'load';
}

function retried(state: MapLoadState): MapLoadState {
  return { failure: null, attempt: state.attempt + 1 };
}

export function nextMapLoadState(
  state: MapLoadState,
  event: MapLoadEvent
): MapLoadState {
  switch (event.type) {
    case 'loadFailed':
      return state.failure || event.attempt !== state.attempt
        ? state
        : { ...state, failure: 'load' };
    case 'buildFailed':
      return state.failure ? state : { ...state, failure: 'build' };
    case 'authFailed':
      return { ...state, failure: 'auth' };
    case 'retry':
      return canRetry(state.failure) ? retried(state) : state;
    case 'resumed':
      return canRetry(state.failure) && event.visible && event.online
        ? retried(state)
        : state;
  }
}
