json.id chapter.id
json.map_id chapter.map_id
json.journey_id chapter.journey_id
json.title chapter.title
json.status chapter.status
json.content chapter.content
json.image chapter.image_variants
json.image_url chapter.image_url
json.author do
  json.id chapter.user.id
  json.name chapter.user.name
  json.biography chapter.user.biography
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
if chapter.user.journal.present?
  json.journal do
    json.id chapter.user.journal.id
    json.title chapter.user.journal.title
  end
else
  json.journal nil
end
json.editable current_user.author?(chapter)
json.liked chapter.liked_by?(current_user)
json.likes_count chapter.votes.size
json.created_at chapter.created_at
json.updated_at chapter.updated_at
