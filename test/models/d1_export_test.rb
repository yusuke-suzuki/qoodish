require 'test_helper'

class D1ExportTest < ActiveSupport::TestCase
  test 'lists every application table once with its parents first' do
    names = D1Export.new.tables.map(&:name)

    assert_equal names.uniq, names
    assert_not_includes names, 'schema_migrations'
    assert_not_includes names, 'ar_internal_metadata'
    assert_operator names.index('users'), :<, names.index('maps')
    assert_operator names.index('maps'), :<, names.index('map_revisions')
    assert_operator names.index('pins'), :<, names.index('pin_revisions')
    assert_operator names.index('pin_revisions'), :<, names.index('pin_revision_images')
  end

  test 'defers the references that point at a table loaded later' do
    tables = D1Export.new.tables.index_by(&:name)

    assert_includes tables['maps'].deferred, 'current_revision_id'
    assert_includes tables['users'].deferred, 'image_id'
    assert_not_includes tables['map_revisions'].deferred, 'map_id'
  end

  test 'loads the deferred references once both sides are in' do
    map = maps(:public_one)
    statements = export_statements

    revisions_loaded = statements.index { |statement| statement.start_with?('INSERT INTO "map_revisions"') }
    update = statements.index do |statement|
      statement.start_with?('UPDATE "maps" SET "current_revision_id" = CASE id') &&
        statement.include?("WHEN #{map.id} THEN #{map.current_revision_id}")
    end

    assert update
    assert_operator revisions_loaded, :<, update
  end

  test 'writes timestamps as ISO 8601 UTC with microseconds' do
    map = maps(:public_one)

    assert_includes export_statements.join("\n"), "'#{map.created_at.utc.strftime('%Y-%m-%dT%H:%M:%S.%6NZ')}'"
  end

  test 'quotes text the way SQLite reads it' do
    map = Map.record!(user: users(:me), name: "Grandma's", description: 'A map', latitude: 35.1, longitude: 139.2)

    assert_includes export_statements.join("\n"), "'Grandma''s'"
    assert_includes export_statements.join("\n"), "(#{map.id}, "
  end

  test 'keeps JSON as MySQL stores it' do
    chapter = chapters(:my_published)
    stored = Chapter.where(id: chapter.id).pick(Arel.sql('CAST(content AS CHAR)'))

    assert_includes export_statements.join("\n"), "'#{stored.gsub("'", "''")}'"
  end

  test 'copies encrypted values without decrypting them' do
    journey = journeys(:my_in_progress)
    ciphertext = Journey.where(id: journey.id).pick(Arel.sql('CAST(encoded_path AS CHAR)'))
    sql = export_statements.join("\n")

    assert_includes sql, "'#{ciphertext.gsub("'", "''")}'"
    assert_not_includes sql, journey.encoded_path
  end

  test 'keeps every statement within the limit and rebuilds longer values in pieces' do
    chapter = chapters(:my_published)
    chapter.revise!(user: chapter.user, content: { root: { type: 'root', text: "#{"it's long " * 400}end" } })
    stored = Chapter.where(id: chapter.id).pick(Arel.sql('CAST(content AS CHAR)'))

    statements = export_statements(statement_limit: 1_000)

    assert(statements.all? { |statement| statement.bytesize <= 1_000 })
    assert_includes rebuilt_values(statements, 'chapters', chapter.id), stored
  end

  test 'splits parts between statements' do
    parts = []
    D1Export.new(statement_limit: 2_000).each_part(5_000) { |number, body| parts << [number, body] }

    assert_operator parts.size, :>, 1
    assert_equal (1..parts.size).to_a, parts.map(&:first)
    assert(parts.all? { |_number, body| body.end_with?(";\n") && body.bytesize <= 5_000 })
    assert_equal export_statements(statement_limit: 2_000).map { |statement| "#{statement}\n" }.join,
                 parts.map(&:last).join
  end

  test 'counts the rows of every table for the import to be checked against' do
    manifest = D1Export.new.manifest

    assert_equal({ rows: Map.count, max_id: Map.maximum(:id) }, manifest['maps'])
    assert_equal D1Export.new.tables.map(&:name).sort, manifest.keys.sort
  end

  private

  def export_statements(**options)
    [].tap { |statements| D1Export.new(**options).each_statement { |statement| statements << statement } }
  end

  def rebuilt_values(statements, table, id)
    slots = {}
    rebuilt = []

    statements.each do |statement|
      case statement
      when /\AINSERT INTO "_d1_export_values" \(id, value\) VALUES \((\d+), '(.*)'\);\z/m
        slots[Regexp.last_match(1).to_i] = unquote(Regexp.last_match(2))
      when /\AUPDATE "_d1_export_values" SET value = value \|\| '(.*)' WHERE id = (\d+);\z/m
        slots[Regexp.last_match(2).to_i] += unquote(Regexp.last_match(1))
      when /\AINSERT INTO "#{table}" .* VALUES \(#{id}, /m
        rebuilt.concat(slots.values)
      when 'DELETE FROM "_d1_export_values";'
        slots = {}
      end
    end

    rebuilt
  end

  def unquote(literal)
    literal.gsub("''", "'")
  end
end
