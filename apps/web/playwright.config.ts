import { defineConfig, devices } from '@playwright/test';
import { LOCAL_API_URL } from './e2e/localApi.ts';

// A deployment is shared by every branch, so a run driving one can answer for
// a commit nobody put up for review. Serving the build here is what ties the
// answer to the commit under test.
const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:8787';

if (process.env.E2E_BASE_URL && !process.env.E2E_API_URL) {
  throw new Error(
    'E2E_BASE_URL needs E2E_API_URL: the local API is only started for the local app.'
  );
}

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI ? 'github' : 'list',
  timeout: 60000,
  expect: { timeout: 15000 },
  use: {
    baseURL,
    serviceWorkers: 'block',
    // Nothing collects these from a CI run: it reports through its log. They
    // must not become artifacts either — a trace records every request the
    // page made, Maps API key included, and this repository is public.
    trace: process.env.CI ? 'off' : 'retain-on-failure',
    screenshot: process.env.CI ? 'off' : 'only-on-failure'
  },
  webServer: process.env.E2E_BASE_URL
    ? undefined
    : [
        {
          command: 'pnpm --filter qoodish-api dev',
          url: `${LOCAL_API_URL}/healthcheck`,
          timeout: 180000,
          reuseExistingServer: !process.env.CI
        },
        {
          command: 'pnpm preview',
          url: baseURL,
          timeout: 180000,
          reuseExistingServer: !process.env.CI
        }
      ],
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'mobile',
      use: { ...devices['Pixel 7'] }
    }
  ]
});
