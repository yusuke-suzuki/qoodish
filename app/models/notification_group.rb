class NotificationGroup
  PER_PAGE = 20
  NOTIFIERS_LIMIT = 2

  Page = Data.define(:groups, :next_cursor)

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

  def self.page(notifications, cursor: nil, unread: false)
    summaries_query =
      notifications
      .group(*Notification::GROUPING_ATTRIBUTES)
      .order('MAX(notifications.id) DESC')
      .limit(PER_PAGE)
    summaries_query = summaries_query.having('MAX(notifications.id) < ?', cursor.to_i) if cursor.present?
    summaries_query = summaries_query.having('MIN(notifications.read) = ?', false) if unread

    summaries = summaries_query.pluck(
      *Notification::GROUPING_ATTRIBUTES,
      'MAX(notifications.id)',
      'MIN(notifications.read)'
    )

    Page.new(
      groups: build_groups(notifications, summaries),
      next_cursor: (summaries.last[3] if summaries.size == PER_PAGE)
    )
  end

  def self.build_groups(notifications, summaries)
    return [] if summaries.empty?

    latest_ids = summaries.map do |key, notifiable_type, notifiable_id, *|
      latest_ids_by_notifier(
        notifications.where(key: key, notifiable_type: notifiable_type, notifiable_id: notifiable_id)
      )
    end
    records = notifications.where(id: latest_ids.flatten).index_by(&:id)
    group_keys = summaries.map { |summary| summary.first(Notification::GROUPING_ATTRIBUTES.size) }
    notifiers_counts =
      notifications
      .where(Notification::GROUPING_ATTRIBUTES => group_keys)
      .group(*Notification::GROUPING_ATTRIBUTES)
      .distinct
      .count(:notifier_id)

    summaries.zip(group_keys, latest_ids).filter_map do |(*, read), group_key, ids|
      notification = records[ids.first]
      next unless notification.renderable?

      new(
        notification: notification,
        notifiers: records.values_at(*ids).map(&:notifier).compact,
        notifiers_count: notifiers_counts.fetch(group_key),
        read: read.to_i == 1
      )
    end
  end
  private_class_method :build_groups

  def self.latest_ids_by_notifier(notifications)
    notifications
      .group(:notifier_id)
      .order('MAX(notifications.id) DESC')
      .limit(NOTIFIERS_LIMIT)
      .pluck('MAX(notifications.id)')
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
