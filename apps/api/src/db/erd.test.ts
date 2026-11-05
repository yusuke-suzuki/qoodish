import { describe, expect, it } from 'vitest';
import readme from '../../README.md?raw';
import { entityRelationshipDiagram, MERMAID_BLOCK } from './erd.ts';

describe('entityRelationshipDiagram', () => {
  it('matches the diagram in README.md, which pnpm db:erd regenerates', () => {
    expect(MERMAID_BLOCK.exec(readme)?.[1]).toBe(entityRelationshipDiagram());
  });
});
