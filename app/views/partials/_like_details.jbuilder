json.id like.id
json.voter do
  json.id like.voter.id
  json.name like.voter.name
  json.profile_image_url like.voter.thumbnail_url
end
json.votable do
  json.id like.votable.id
  json.type like.votable_type.downcase
  json.name like.votable.name
  json.thumbnail_url like.votable.thumbnail_url
  json.owner do
    json.id like.votable.user.id
    json.name like.votable.user.name
  end
end
if like.votable_type == Review.name
  json.click_action "/maps/#{like.votable.map_id}/reports/#{like.votable.id}"
elsif like.votable_type == Map.name
  json.click_action "/maps/#{like.votable.id}"
else
  json.click_action '/'
end
json.created_at like.created_at
json.updated_at like.updated_at
