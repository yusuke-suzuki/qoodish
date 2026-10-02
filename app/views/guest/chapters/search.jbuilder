json.array! @chapters do |chapter|
  json.id chapter.id
  json.title chapter.title
  json.image chapter.image_variants
  json.map do
    json.id chapter.map_id
    json.name chapter.map.name
  end
end
