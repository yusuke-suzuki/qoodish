import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { withDiagram } from '../src/db/erd.ts';

const readme = path.join(import.meta.dirname, '../README.md');

writeFileSync(readme, withDiagram(readFileSync(readme, 'utf8')));
