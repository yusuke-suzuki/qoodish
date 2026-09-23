json.id comment.id
json.author do
  json.id comment.user.id
  json.name comment.user.name
  json.image comment.user.image_variants
  json.image_url comment.user.image_url
end
json.body comment.body
json.liked comment.liked_by?(current_user)
json.likes_count comment.votes.length
json.created_at comment.created_at
json.updated_at comment.updated_at
