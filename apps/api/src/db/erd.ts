import { getTableName, is } from 'drizzle-orm';
import {
  getTableConfig,
  type SQLiteColumn,
  SQLiteTable
} from 'drizzle-orm/sqlite-core';
import * as schema from './schema.ts';

const DATA_MODEL_DIAGRAM =
  /(## Data model\n[\s\S]*?```mermaid\n)[\s\S]*?(\n```)/;

type TableConfig = ReturnType<typeof getTableConfig>;

function byCodeUnit(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

function sameColumns(a: SQLiteColumn[], b: SQLiteColumn[]): boolean {
  const names = new Set(a.map((column) => column.name));
  return a.length === b.length && b.every((column) => names.has(column.name));
}

function isUnique(config: TableConfig, columns: SQLiteColumn[]): boolean {
  return (
    (columns.length === 1 && (columns[0].primary || columns[0].isUnique)) ||
    config.indexes.some(
      (index) =>
        index.config.unique &&
        sameColumns(index.config.columns as SQLiteColumn[], columns)
    ) ||
    config.uniqueConstraints.some((unique) =>
      sameColumns(unique.columns, columns)
    ) ||
    config.primaryKeys.some((key) => sameColumns(key.columns, columns))
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

      return `  ${getTableName(foreignTable)} ${parent}--${child} ${config.name} : "${label}"`;
    })
    .sort(byCodeUnit);
}

export function entityRelationshipDiagram(): string {
  const configs = Object.values(schema)
    .filter((value) => is(value, SQLiteTable))
    .map((table) => getTableConfig(table))
    .sort((a, b) => byCodeUnit(a.name, b.name));

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

export function withDiagram(readme: string): string {
  if (!DATA_MODEL_DIAGRAM.test(readme)) {
    throw new Error('README.md has no mermaid block under "## Data model"');
  }

  return readme.replace(
    DATA_MODEL_DIAGRAM,
    (_, before: string, after: string) =>
      `${before}${entityRelationshipDiagram()}${after}`
  );
}
