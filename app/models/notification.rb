class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :notifier, polymorphic: true
  belongs_to :recipient, polymorphic: true

  KEYS = %w[coauthor_invited liked comment bookmarked].freeze
  FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

  validates :notifiable_type,
            inclusion: {
              in: [Review.name, Map.name, Comment.name, Chapter.name, Journal.name]
            }
  validates :notifier_type,
            inclusion: {
              in: [User.name]
            }
  validates :recipient_type,
            inclusion: {
              in: [User.name]
            }
  validates :key,
            inclusion: {
              in: KEYS
            }

  after_create_commit :bloadcast_web_push_later

  scope :recent, lambda {
    order(created_at: :desc)
      .limit(10)
  }

  # Resolve keys retired with their feature to the current key that carries the
  # same meaning, on read, so historical rows keep displaying without rewriting
  # data. 'invited' became 'coauthor_invited', and following a map became
  # bookmarking it. Following a user has no equivalent, so it stays unresolved
  # and unrenderable.
  def resolved_key
    case key
    when 'invited'
      'coauthor_invited'
    when 'followed'
      notifiable_type == Map.name ? 'bookmarked' : key
    else
      key
    end
  end

  def renderable?
    KEYS.include?(resolved_key)
  end

  def click_action
    case resolved_key
    when 'coauthor_invited'
      '/coauthorship_invitations'
    when 'bookmarked'
      case notifiable_type
      when Map.name
        "/maps/#{notifiable.id}"
      when Journal.name
        "/users/#{notifiable.user_id}"
      else
        ''
      end
    when 'comment'
      "/maps/#{notifiable.map_id}/reports/#{notifiable.id}"
    when 'liked'
      case notifiable_type
      when Review.name
        "/maps/#{notifiable.map_id}/reports/#{notifiable.id}"
      when Map.name
        "/maps/#{notifiable.id}"
      when Comment.name
        "/maps/#{notifiable.commentable.map_id}/reports/#{notifiable.commentable.id}"
      when Chapter.name
        "/chapters/#{notifiable.id}"
      else
        ''
      end
    else
      ''
    end
  end

  def bloadcast_web_push
    google_auth = GoogleAuth.new
    access_token = google_auth.fetch_access_token(FCM_SCOPE)

    headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': "Bearer #{access_token}"
    }

    data = {
      icon: notifier.image_variants&.dig(:avatar).to_s,
      click_action: "#{ENV['WEB_ENDPOINT']}#{click_action}",
      notification_id: id.to_s,
      key: key,
      notifier_id: notifier_id.to_s,
      notifier_name: notifier.name,
      notifiable_id: notifiable_id.to_s,
      notifiable_type: notifiable_type.downcase
    }

    recipient.devices.each do |device|
      body = {
        validate_only: Rails.env.test?,
        message: {
          token: device.registration_token,
          data: data
        }
      }

      response = Faraday.post(
        "https://fcm.googleapis.com/v1/projects/#{ENV['GOOGLE_PROJECT_ID']}/messages:send",
        body.to_json,
        headers
      )

      next unless [404, 400].include?(response.status)

      device.destroy!

      Rails.logger.info("Device #{device.id} is destroyed because it is not found or unregistered.")
    end
  end

  def allowed_web_push?
    if recipient.push_notification.blank?
      false
    else
      recipient.push_notification[key]
    end
  end

  private

  def bloadcast_web_push_later
    return unless allowed_web_push?

    BloadcastWebPushJob.perform_later(self)
  end
end
