json.array! @users do |user|
  json.id user.id
  json.name user.name
  json.image user.image_variants
  json.image_url user.image_url
end
