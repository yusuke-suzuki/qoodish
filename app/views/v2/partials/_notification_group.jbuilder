notification = group.notification

json.id notification.id
json.key notification.key
json.click_action notification.click_action
json.notifiable do
  json.id notification.notifiable_id
  json.type notification.notifiable_type.downcase
  json.image notification.notifiable.image_variants
  json.image_url notification.notifiable.image_url
end
json.notifier do
  json.partial! 'partials/notifier', notifier: notification.notifier
end
json.read group.read?
json.notifiers group.notifiers, partial: 'partials/notifier', as: :notifier
json.notifiers_count group.notifiers_count
json.created_at notification.created_at
json.updated_at notification.updated_at
