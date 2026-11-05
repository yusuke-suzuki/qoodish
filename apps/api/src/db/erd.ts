import { getTableConfig, type SQLiteColumn } from 'drizzle-orm/sqlite-core';
import * as schema from './schema.ts';

export const MERMAID_BLOCK = /```mermaid\n([\s\S]*?)\n```/;

type TableConfig = ReturnType<typeof getTableConfig>;

function sameColumns(a: SQLiteColumn[], b: SQLiteColumn[]): boolean {
  return (
    a.length === b.length && a.every((column, i) => column.name === b[i].name)
  );
}

function isUnique(config: TableConfig, columns: SQLiteColumn[]): boolean {
  return (
    (columns.length === 1 && (columns[0].primary || columns[0].isUnique)) ||
    config.indexes.some(
      (index) =>
        index.config.unique &&
        sameColumns(index.config.columns as SQLiteColumn[], columns)
    )
  );
}

function attribute(config: TableConfig, column: SQLiteColumn): string {
  const keys = [
    column.primary && 'PK',
    config.foreignKeys.some((fk) =>
      fk.reference().columns.some((c) => c.name === column.name)
    ) && 'FK',
    !column.primary && isUnique(config, [column]) && 'UK'
  ].filter(Boolean);

  return `    ${column.getSQLType()} ${column.name}${keys.length > 0 ? ` ${keys.join(', ')}` : ''}`;
}

function relationships(config: TableConfig): string[] {
  return config.foreignKeys
    .map((fk) => {
      const { columns, foreignTable } = fk.reference();
      const parent = columns.every((column) => column.notNull) ? '||' : '|o';
      const child = isUnique(config, columns) ? 'o|' : 'o{';
      const label = columns.map((column) => column.name).join(', ');

      return `  ${getTableConfig(foreignTable).name} ${parent}--${child} ${config.name} : "${label}"`;
    })
    .sort();
}

export function entityRelationshipDiagram(): string {
  const configs = Object.values(schema)
    .map((table) => getTableConfig(table))
    .sort((a, b) => a.name.localeCompare(b.name));

  return [
    'erDiagram',
    ...configs.flatMap(relationships),
    ...configs.flatMap((config) => [
      `  ${config.name} {`,
      ...config.columns.map((column) => attribute(config, column)),
      '  }'
    ])
  ].join('\n');
}
