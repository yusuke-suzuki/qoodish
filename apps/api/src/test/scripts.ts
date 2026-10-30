import { env } from 'cloudflare:test';

export async function runScript(script: string): Promise<void> {
  const statements = script
    .split(';')
    .map((statement) => statement.trim())
    .filter((statement) => statement !== '');

  await env.DB.batch(statements.map((statement) => env.DB.prepare(statement)));
}
