destination = ARGV.first.presence
abort 'Usage: bin/rails runner lib/tasks/export_for_d1.rb gs://BUCKET/PREFIX | DIRECTORY' unless destination

write = if destination.start_with?('gs://')
          storage = GoogleCloudStorage.new(destination)
          ->(name, body, content_type) { storage.put(name, body, content_type: content_type) }
        else
          FileUtils.mkdir_p(destination)
          ->(name, body, _content_type) { File.binwrite(File.join(destination, name), body) }
        end

export = D1Export.new

export.each_part(D1Export::PART_BYTES) do |number, body|
  name = format('part-%05d.sql', number)
  write.call(name, body, 'application/sql')
  Rails.logger.info("D1 export: wrote #{name} (#{body.bytesize} bytes)")
end

write.call('manifest.json', JSON.pretty_generate(export.manifest), 'application/json')
Rails.logger.info("D1 export: wrote manifest.json for #{export.tables.size} tables to #{destination}")
