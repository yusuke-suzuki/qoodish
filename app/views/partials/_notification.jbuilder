json.id notification.id
json.key notification.key
json.click_action notification.click_action
json.notifiable do
  json.id notification.notifiable_id
  json.type notification.client_notifiable_type
  json.image notification.notifiable.image_variants
  json.image_url notification.notifiable.image_url
end
json.notifier do
  json.partial! 'partials/notifier', notifier: notification.notifier
end
json.read notification.read
json.created_at notification.created_at
json.updated_at notification.updated_at
