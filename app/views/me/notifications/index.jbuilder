json.array! @notification_groups do |group|
  json.partial! 'partials/notification', notification: group.notification
  json.read group.read?
  json.notifiers group.notifiers, partial: 'partials/notifier', as: :notifier
  json.notifiers_count group.notifiers_count
end
