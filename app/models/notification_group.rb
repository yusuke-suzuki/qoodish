class NotificationGroup
  NOTIFIERS_LIMIT = 2

  attr_reader :notification, :notifiers, :notifiers_count

  def self.recent(notifications, limit: 10)
    summaries =
      notifications
      .group(*Notification::GROUPING_ATTRIBUTES)
      .order(Arel.sql('MAX(notifications.id) DESC'))
      .limit(limit)
      .pluck(
        *Notification::GROUPING_ATTRIBUTES,
        Arel.sql('COUNT(DISTINCT notifications.notifier_id)'),
        Arel.sql('MIN(notifications.read)')
      )

    latest_ids = summaries.map do |key, notifiable_type, notifiable_id, *|
      latest_ids_by_notifier(
        notifications.where(key: key, notifiable_type: notifiable_type, notifiable_id: notifiable_id)
      )
    end
    records = notifications.where(id: latest_ids.flatten).index_by(&:id)

    summaries.zip(latest_ids).filter_map do |(*, notifiers_count, read), ids|
      notification = records[ids.first]
      next unless notification.renderable?

      new(
        notification: notification,
        notifiers: records.values_at(*ids).map(&:notifier).compact,
        notifiers_count: notifiers_count,
        read: read.to_i == 1
      )
    end
  end

  def self.latest_ids_by_notifier(notifications)
    notifications
      .group(:notifier_id)
      .order(Arel.sql('MAX(notifications.id) DESC'))
      .limit(NOTIFIERS_LIMIT)
      .pluck(Arel.sql('MAX(notifications.id)'))
  end
  private_class_method :latest_ids_by_notifier

  def initialize(notification:, notifiers:, notifiers_count:, read:)
    @notification = notification
    @notifiers = notifiers
    @notifiers_count = notifiers_count
    @read = read
  end

  def read?
    @read
  end
end
