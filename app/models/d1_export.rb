# frozen_string_literal: true

class D1Export
  STATEMENT_LIMIT = 90_000
  PART_BYTES = 32.megabytes
  BATCH_SIZE = 50
  UPDATES_PER_STATEMENT = 500
  INTERNAL_TABLES = %w[ar_internal_metadata schema_migrations].freeze
  SCRATCH_TABLE = '_d1_export_values'
  INTEGER_TYPES = %w[tinyint smallint mediumint int bigint].freeze
  REAL_TYPES = %w[decimal float double].freeze
  TIME_TYPES = %w[datetime timestamp].freeze
  BINARY_TYPES = %w[binary varbinary tinyblob blob mediumblob longblob].freeze
  REAL_LITERAL = /\A-?\d+(\.\d+)?(e[+-]?\d+)?\z/i.freeze
  QUOTED_CHARACTERS = { "'" => "''", "\0" => "' || char(0) || '" }.freeze
  QUOTED_PATTERN = /['\0]/.freeze

  Column = Data.define(:name, :data_type, :nullable)
  Table = Data.define(:name, :columns, :deferred)

  attr_reader :statement_limit

  def initialize(connection: ApplicationRecord.lease_connection, statement_limit: STATEMENT_LIMIT)
    @connection = connection
    @statement_limit = statement_limit
  end

  def tables
    @tables ||= ordered_tables
  end

  def each_statement(&block)
    yield "CREATE TABLE #{quote_identifier(SCRATCH_TABLE)} (id INTEGER PRIMARY KEY, value TEXT NOT NULL);"
    tables.each { |table| each_insert(table, &block) }
    tables.each { |table| each_deferred_update(table, &block) }
    yield "DROP TABLE #{quote_identifier(SCRATCH_TABLE)};"
  end

  def each_part(bytes)
    number = 0
    part = +''

    each_statement do |statement|
      if part.present? && part.bytesize + statement.bytesize + 1 > bytes
        yield(number += 1, part)
        part = +''
      end

      part << statement << "\n"
    end

    yield(number + 1, part) if part.present?
  end

  def manifest
    tables.to_h do |table|
      rows, max_id = connection.select_rows(
        "SELECT COUNT(*), MAX(id) FROM #{connection.quote_table_name(table.name)}"
      ).first

      [table.name, { rows: rows, max_id: max_id }]
    end
  end

  private

  attr_reader :connection

  def ordered_tables
    columns = table_names.index_with { |name| columns_of(name) }
    references = foreign_keys.select { |table, _column, referenced| columns.key?(table) && columns.key?(referenced) }
    required = references.reject do |table, column, referenced|
      referenced == table || columns[table].find { |candidate| candidate.name == column }.nullable
    end
    position = topological_order(columns.keys, required).each_with_index.to_h

    position.keys.map do |name|
      deferred = references.filter_map do |table, column, referenced|
        column if table == name && position[referenced] >= position[name]
      end

      Table.new(name: name, columns: columns[name], deferred: deferred)
    end
  end

  def topological_order(names, references)
    parents = names.index_with { Set.new }
    references.each { |table, _column, referenced| parents[table] << referenced }

    remaining = names.sort
    order = []

    until remaining.empty?
      ready = remaining.find { |name| parents[name].subset?(order.to_set) }
      raise ArgumentError, "Required foreign keys form a cycle among #{remaining.join(', ')}" unless ready

      order << remaining.delete(ready)
    end

    order
  end

  def table_names
    connection.select_values(<<~SQL.squish) - INTERNAL_TABLES
      SELECT table_name FROM information_schema.tables
      WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
    SQL
  end

  def columns_of(table)
    rows = connection.select_rows(<<~SQL.squish)
      SELECT column_name, data_type, is_nullable FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = #{connection.quote(table)}
      ORDER BY ordinal_position
    SQL
    raise ArgumentError, "#{table} has no id column to page through" if rows.none? { |row| row.first == 'id' }

    rows.map { |name, type, nullable| Column.new(name: name, data_type: type.downcase, nullable: nullable == 'YES') }
  end

  def foreign_keys
    connection.select_rows(<<~SQL.squish)
      SELECT table_name, column_name, referenced_table_name FROM information_schema.key_column_usage
      WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL
    SQL
  end

  def each_insert(table)
    header = "INSERT INTO #{quote_identifier(table.name)} " \
             "(#{table.columns.map { |column| quote_identifier(column.name) }.join(', ')}) VALUES "
    tuples = []
    size = header.bytesize

    each_row(table) do |row|
      values = table.columns.zip(row).map do |column, value|
        [column, table.deferred.include?(column.name) ? nil : value]
      end
      tuple = "(#{values.map { |column, value| literal(column, value) }.join(', ')})"

      if size + tuple.bytesize + 2 > statement_limit && tuples.any?
        yield "#{header}#{tuples.join(', ')};"
        tuples = []
        size = header.bytesize
      end

      if header.bytesize + tuple.bytesize + 1 > statement_limit
        each_oversized_insert(header, values) { |statement| yield statement }
        next
      end

      tuples << tuple
      size += tuple.bytesize + 2
    end

    yield "#{header}#{tuples.join(', ')};" if tuples.any?
  end

  def each_oversized_insert(header, values)
    literals = values.map { |column, value| literal(column, value) }
    slots = 0

    while header.bytesize + literals.sum { |literal| literal.bytesize + 2 } + 1 > statement_limit
      index = literals.each_index
                      .select { |i| values[i].last.is_a?(String) && literals[i].start_with?("'") }
                      .max_by { |i| literals[i].bytesize }
      raise ArgumentError, "A row of #{header.split.third} does not fit in #{statement_limit} bytes" unless index

      slots += 1
      each_slot_statement(slots, values[index].last) { |statement| yield statement }
      literals[index] = "(SELECT value FROM #{quote_identifier(SCRATCH_TABLE)} WHERE id = #{slots})"
    end

    yield "#{header}(#{literals.join(', ')});"
    yield "DELETE FROM #{quote_identifier(SCRATCH_TABLE)};"
  end

  def each_slot_statement(slot, text)
    scratch = quote_identifier(SCRATCH_TABLE)
    first = true

    each_chunk(text) do |chunk|
      yield(
        if first
          "INSERT INTO #{scratch} (id, value) VALUES (#{slot}, #{quote_text(chunk)});"
        else
          "UPDATE #{scratch} SET value = value || #{quote_text(chunk)} WHERE id = #{slot};"
        end
      )
      first = false
    end
  end

  def each_chunk(text)
    limit = statement_limit - 200
    chunk = +''
    size = 0

    text.each_char do |char|
      char_size = QUOTED_CHARACTERS.fetch(char, char).bytesize

      if size + char_size > limit
        yield chunk
        chunk = +''
        size = 0
      end

      chunk << char
      size += char_size
    end

    yield chunk unless chunk.empty?
  end

  def each_deferred_update(table)
    table_name = quote_identifier(table.name)

    table.deferred.each do |column|
      column_name = quote_identifier(column)

      each_reference(table, column).each_slice(UPDATES_PER_STATEMENT) do |pairs|
        cases = pairs.map { |id, value| "WHEN #{Integer(id)} THEN #{Integer(value)}" }.join(' ')
        ids = pairs.map { |id, _value| Integer(id) }.join(', ')

        yield "UPDATE #{table_name} SET #{column_name} = CASE id #{cases} END WHERE id IN (#{ids});"
      end
    end
  end

  def each_reference(table, column)
    return to_enum(:each_reference, table, column) unless block_given?

    quoted = connection.quote_column_name(column)
    last_id = 0

    loop do
      rows = connection.select_rows(<<~SQL.squish)
        SELECT id, #{quoted} FROM #{connection.quote_table_name(table.name)}
        WHERE id > #{last_id} AND #{quoted} IS NOT NULL ORDER BY id LIMIT #{UPDATES_PER_STATEMENT}
      SQL
      break if rows.empty?

      rows.each { |row| yield row }
      last_id = rows.last.first
    end
  end

  def each_row(table)
    selection = table.columns.map { |column| select_expression(column) }.join(', ')
    id_index = table.columns.index { |column| column.name == 'id' }
    last_id = 0

    loop do
      rows = connection.select_rows(<<~SQL.squish)
        SELECT #{selection} FROM #{connection.quote_table_name(table.name)}
        WHERE id > #{last_id} ORDER BY id LIMIT #{BATCH_SIZE}
      SQL
      break if rows.empty?

      rows.each { |row| yield row }
      last_id = rows.last[id_index]
    end
  end

  def select_expression(column)
    name = connection.quote_column_name(column.name)

    case column.data_type
    when *TIME_TYPES then "DATE_FORMAT(#{name}, '%Y-%m-%dT%H:%i:%s.%fZ')"
    when 'date' then "DATE_FORMAT(#{name}, '%Y-%m-%d')"
    when *REAL_TYPES, 'json' then "CAST(#{name} AS CHAR)"
    else name
    end
  end

  def literal(column, value)
    return 'NULL' if value.nil?

    case column.data_type
    when *INTEGER_TYPES then Integer(value).to_s
    when *REAL_TYPES then real_literal(value)
    when *BINARY_TYPES then "X'#{value.unpack1('H*')}'"
    else quote_text(value.to_s)
    end
  end

  def real_literal(value)
    text = value.to_s
    raise ArgumentError, "#{text.inspect} is not a number" unless text.match?(REAL_LITERAL)

    text
  end

  def quote_text(text)
    "'#{text.gsub(QUOTED_PATTERN, QUOTED_CHARACTERS)}'"
  end

  def quote_identifier(name)
    %("#{name.gsub('"', '""')}")
  end
end
