json.array! @blocks do |block|
  json.id block.blocked.id
  json.name block.blocked.name
  json.biography block.blocked.biography
  json.image block.blocked.image_variants
  json.image_url block.blocked.image_url
  json.cursor block.id
end
