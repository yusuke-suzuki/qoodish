json.id chapter.id
json.map_id chapter.map_id
json.journey_id chapter.journey_id
json.title chapter.title
json.status chapter.status
json.content chapter.content
json.author do
  json.id chapter.user.id
  json.name chapter.user.name
  json.image chapter.user.image_variants
  json.image_url chapter.user.image_url
end
if chapter.map.present?
  json.map do
    json.id chapter.map_id
    json.name chapter.map.name
    json.private chapter.map.private
  end
else
  json.map nil
end
json.editable current_user.author?(chapter)
json.created_at chapter.created_at
json.updated_at chapter.updated_at
