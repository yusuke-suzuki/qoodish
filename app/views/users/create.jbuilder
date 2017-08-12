json.user do
  json.uid @user.uid
  json.email @user.email
  json.name @user.name
  json.image_url: @user.image_url
  json.provider: @user.provider
end
