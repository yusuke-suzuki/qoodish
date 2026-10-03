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
        Arel.sql('MAX(notifications.id)'),
        Arel.sql('COUNT(DISTINCT notifications.notifier_id)'),
        Arel.sql('MIN(notifications.read)')
      )

    latest =
      Notification
      .where(id: summaries.map(&:first))
      .includes({ notifier: :image }, :notifiable)
      .index_by(&:id)

    notifier_ids = summaries.to_h do |id, _, _|
      [id, recent_notifier_ids(notifications.grouped_with(latest[id]))]
    end
    users = User.where(id: notifier_ids.values.flatten).includes(:image).index_by(&:id)

    groups = summaries.filter_map do |id, notifiers_count, read|
      notification = latest[id]
      next unless notification.renderable?

      new(
        notification: notification,
        notifiers: users.values_at(*notifier_ids[id]).compact,
        notifiers_count: notifiers_count,
        read: read.to_i == 1
      )
    end

    preload_notifiable_images(groups.map { |group| group.notification.notifiable })

    groups
  end

  def self.preload_notifiable_images(notifiables)
    comments, others = notifiables.partition { |notifiable| notifiable.is_a?(Comment) }

    ActiveRecord::Associations::Preloader.new(records: others, associations: :images).call
    ActiveRecord::Associations::Preloader.new(records: comments, associations: { commentable: :images }).call
  end
  private_class_method :preload_notifiable_images

  def self.recent_notifier_ids(notifications)
    notifications
      .group(:notifier_id)
      .order(Arel.sql('MAX(notifications.id) DESC'))
      .limit(NOTIFIERS_LIMIT)
      .pluck(:notifier_id)
  end
  private_class_method :recent_notifier_ids

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
