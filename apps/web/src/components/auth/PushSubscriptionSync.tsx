'use client';

import { useContext } from 'react';
import ServiceWorkerContext from '../../context/ServiceWorkerContext.ts';
import { usePushManager } from '../../hooks/usePushManager.ts';

export default function PushSubscriptionSync() {
  const { registration } = useContext(ServiceWorkerContext);

  usePushManager(registration);

  return null;
}
