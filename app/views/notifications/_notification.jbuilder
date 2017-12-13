json.id notification.id
json.key notification.key
if notification.notifiable.present?
  json.notifiable do
    json.id notification.notifiable_id
    json.notifiable_type notification.notifiable_type
    if notification.notifiable_type == 'Review'
      json.image_url notification.notifiable.image_url
      json.map_id notification.notifiable.map_id
    end
  end
end
if notification.notifier.present?
  json.notifier do
    json.id notification.notifier_id
    json.name notification.notifier.name
    json.profile_image_url notification.notifier.image_url
  end
end
json.read notification.read
json.created_at notification.created_at
json.updated_at notification.updated_at
