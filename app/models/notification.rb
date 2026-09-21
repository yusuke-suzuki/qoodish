class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :notifier, polymorphic: true
  belongs_to :recipient, polymorphic: true

  KEYS = %w[coauthor_invited liked comment published].freeze

  FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

  # Clients released before the rename look their message up by the name the
  # subject had then, so a pin keeps arriving as a review until they are out
  # of service.
  RENAMED_NOTIFIABLE_TYPES = { 'Pin' => 'review' }.freeze

  validates :notifiable_type,
            inclusion: {
              in: [Pin.name, Map.name, Comment.name, Chapter.name]
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

  after_create_commit :broadcast_web_push_later

  scope :recent, lambda {
    order(created_at: :desc)
      .limit(10)
  }

  # Rows created before a feature was retired can carry keys outside KEYS
  # ('followed', 'invited'); they reference concepts and data that no longer
  # exist, so they are kept but never served.
  scope :renderable, lambda {
    where(key: KEYS)
  }

  def client_notifiable_type
    RENAMED_NOTIFIABLE_TYPES.fetch(notifiable_type, notifiable_type.downcase)
  end

  def renderable?
    return false if notifier.blank?

    case notifiable
    when Comment then visible?(notifiable) && visible?(notifiable.commentable)
    else visible?(notifiable)
    end
  end

  def click_action
    case key
    when 'coauthor_invited'
      '/coauthorship_invitations'
    when 'comment'
      "/pins/#{notifiable.id}"
    when 'liked'
      case notifiable_type
      when Pin.name
        "/pins/#{notifiable.id}"
      when Map.name
        "/maps/#{notifiable.id}"
      when Comment.name
        "/pins/#{notifiable.commentable.id}"
      when Chapter.name
        "/chapters/#{notifiable.id}"
      else
        ''
      end
    when 'published'
      notifiable_type == Chapter.name ? "/chapters/#{notifiable.id}" : ''
    else
      ''
    end
  end

  def broadcast_web_push
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
      notifiable_type: client_notifiable_type
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
    recipient.web_push_preferences[key]
  end

  private

  def visible?(record)
    return false if record.blank?

    !record.respond_to?(:deleted?) || !record.deleted?
  end

  def broadcast_web_push_later
    return unless allowed_web_push?

    BroadcastWebPushJob.perform_later(self)
  end
end
