json.data @blocks do |block|
  json.id block.blocked.id
  json.name block.blocked.name
  json.biography block.blocked.biography
  json.image block.blocked.image_variants
  json.image_url block.blocked.image_url
end
json.next_cursor @next_cursor
