class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :notifier, polymorphic: true
  belongs_to :recipient, polymorphic: true

  KEYS = %w[followed invited liked comment].freeze
  FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

  validates :notifiable_type,
            inclusion: {
              in: [Review.name, Map.name, Comment.name]
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

  after_create_commit :web_push

  scope :recent, lambda {
    order(created_at: :desc)
      .limit(10)
  }

  def click_action
    case key
    when 'followed'
      "/maps/#{notifiable.id}"
    when 'invited'
      '/invites'
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
      else
        ''
      end
    else
      ''
    end
  end

  def web_push
    return unless allowed_web_push?

    begin
      response = Faraday.post(
        "https://fcm.googleapis.com/v1/projects/#{ENV['GOOGLE_PROJECT_ID']}/messages:send",
        {
          message: {
            topic: "user_#{recipient.id}",
            data: {
              icon: notifier.thumbnail_url,
              click_action: "#{ENV['WEB_ENDPOINT']}#{click_action}",
              notification_id: id.to_s,
              key: key,
              notifier_id: notifier_id.to_s,
              notifier_name: notifier.name,
              notifiable_id: notifiable_id.to_s,
              notifiable_type: notifiable_type.downcase
            }
          }
        }.to_json,
        {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': "Bearer #{authenticate_firebase_admin}"
        }
      )

      Rails.logger.info(response.body)
    rescue => e
      Rails.logger.error("Exception when calling web_push: #{e}")
    end
  end

  def authenticate_firebase_admin
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: FCM_SCOPE
    )
    token = authorizer.fetch_access_token!
    token['access_token']
  end

  def allowed_web_push?
    if recipient.push_notification.blank?
      true
    else
      recipient.push_notification[key]
    end
  end
end
