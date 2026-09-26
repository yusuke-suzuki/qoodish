json.id staff_member.id
json.email staff_member.email
json.revoked_at staff_member.revoked_at
json.roles staff_member.roles.sort_by(&:name) do |role|
  json.id role.id
  json.name role.name
end
