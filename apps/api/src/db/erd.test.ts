import { describe, expect, it } from 'vitest';
import readme from '../../README.md?raw';
import { withDiagram } from './erd.ts';

describe('withDiagram', () => {
  it('leaves README.md unchanged, so its diagram matches the schema (pnpm db:erd regenerates it)', () => {
    expect(readme).toBe(withDiagram(readme));
  });

  it('replaces only the diagram under "## Data model"', () => {
    const other = '## Flow\n\n```mermaid\nflowchart LR\n  a --> b\n```\n\n';
    const result = withDiagram(
      `${other}## Data model\n\n\`\`\`mermaid\nerDiagram\n\`\`\`\n`
    );

    expect(result.startsWith(other)).toBe(true);
    expect(result).toContain('erDiagram\n  ');
  });
});
