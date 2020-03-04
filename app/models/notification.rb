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

    FcmClient.configure do |config|
      config.api_key['Authorization'] = authenticate_firebase_admin
      config.api_key_prefix['Authorization'] = 'Bearer'
      config.debugging = Rails.env.development?
    end
    api_instance = FcmClient::MessagesApi.new

    message = FcmClient::Message.new(
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
    )
    inline_object = FcmClient::InlineObject.new(message: message)

    begin
      result = api_instance.v1_projects_project_id_messagessend_post(ENV['GOOGLE_PROJECT_ID'], inline_object)
      Rails.logger.info(result)
    rescue FcmClient::ApiError => e
      Rails.logger.error("Exception when calling MessagesApi->v1_projects_project_id_messagessend_post: #{e}")
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
