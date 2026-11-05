import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { entityRelationshipDiagram, MERMAID_BLOCK } from '../src/db/erd.ts';

const readme = path.join(import.meta.dirname, '../README.md');
const current = readFileSync(readme, 'utf8');

if (!MERMAID_BLOCK.test(current)) {
  throw new Error('README.md has no mermaid block to replace');
}

writeFileSync(
  readme,
  current.replace(
    MERMAID_BLOCK,
    `\`\`\`mermaid\n${entityRelationshipDiagram()}\n\`\`\``
  )
);
