json.id collaborator.id
json.name collaborator.name
json.profile_image_url collaborator.image_url
json.owner collaborator.map_owner?(@map)
json.editable current_user.map_owner?(@map)
json.created_at collaborator.created_at
json.updated_at collaborator.updated_at
