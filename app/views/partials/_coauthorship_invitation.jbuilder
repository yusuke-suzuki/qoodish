json.id coauthorship_invitation.id
json.map do
  json.id coauthorship_invitation.map_id
  json.name coauthorship_invitation.map.name
  json.description coauthorship_invitation.map.description
  json.image coauthorship_invitation.map.image_variants
  json.image_url coauthorship_invitation.map.image_url
end
json.inviter do
  json.id coauthorship_invitation.inviter_id
  json.name coauthorship_invitation.inviter.name
  json.image coauthorship_invitation.inviter.image_variants
  json.image_url coauthorship_invitation.inviter.image_url
end
json.status coauthorship_invitation.status
json.created_at coauthorship_invitation.created_at
json.updated_at coauthorship_invitation.updated_at
