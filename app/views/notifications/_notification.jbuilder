json.id notification.id
json.key notification.key
json.click_action notification.click_action
json.notifiable do
  json.id notification.notifiable_id
  json.type notification.notifiable_name
  json.thumbnail_url notification.notifiable.thumbnail_url
end
json.notifier do
  json.id notification.notifier_id
  json.name notification.notifier.name
  json.profile_image_url notification.notifier.image_url
end
json.read notification.read
json.created_at notification.created_at
json.updated_at notification.updated_at
