import { type AnalyticsEvent, toDataPoint } from '../utils/analyticsEvent.ts';
import { env } from './workerEnv.ts';

export function recordEvent(event: AnalyticsEvent): void {
  env.ANALYTICS_EVENTS?.writeDataPoint(toDataPoint(event));
}
