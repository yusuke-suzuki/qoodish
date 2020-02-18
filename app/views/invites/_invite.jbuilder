json.id invite.id
json.invitable do
  json.id invite.invitable_id
  json.type invite.invitable_name
  json.image_url invite.invitable.thumbnail_url
  json.name invite.invitable.name
  json.description invite.invitable.description
end
json.sender do
  json.id invite.sender_id
  json.name invite.sender.name
  json.profile_image_url invite.sender.thumbnail_url
end
json.expired invite.expired
json.created_at invite.created_at
json.updated_at invite.updated_at
