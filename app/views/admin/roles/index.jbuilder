json.array! @roles do |role|
  json.id role.id
  json.name role.name
  json.description role.description
  json.permissions role.role_permissions.map(&:permission).sort
end
