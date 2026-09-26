# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/autorun'

ENV['CLOUDFLARE_ACCOUNT_ID'] ||= 'test-account'
ENV['CLOUDFLARE_IMAGES_ACCOUNT_HASH'] ||= 'mockhash'
ENV['CLOUDFLARE_IMAGES_API_TOKEN'] ||= 'test-token'
ENV['REPORT_NOTIFICATION_EMAIL'] ||= 'operator@example.com'

class ActiveSupport::TestCase
  fixtures :all

  # The middleware assigns I18n.locale per request and never restores it, so a
  # test that sends Accept-Language would otherwise set the language for every
  # test that runs after it.
  teardown do
    RequestContext.reset
    I18n.locale = I18n.default_locale
  end

  def stub_google_auth(current_user, &block)
    GoogleAuth.stub :new, GoogleAuthMock.new(current_user), &block
  end

  def stub_cloudflare_access(email, &block)
    CloudflareAccess.stub :new, CloudflareAccessMock.new(email), &block
  end

  def stub_identity_platform(&block)
    IdentityPlatform.stub :new, IdentityPlatformMock.new, &block
  end

  def stub_cloudflare_images(&block)
    Cloudflare::Images.stub :new, CloudflareImagesMock.new, &block
  end

  def record_user(name)
    User.record!(uid: "#{name}-uid", name: name, email: "#{name}@example.com")
  end

  def decide(moderatable, outcome:, reason:)
    report = Report.create!(moderatable: moderatable, reporter: record_user("reporter-#{SecureRandom.hex(4)}"),
                            category: 'spam')

    report.decide!(staff_member: staff_members(:moderator), outcome: outcome, reason: reason)
  end

  def error_message_keys(model, locale)
    attributes = I18n.t("activerecord.errors.models.#{model}.attributes", locale: locale, fallback: false)

    attributes.flat_map { |attribute, keys| (keys.keys - [:format]).map { |key| "#{attribute}.#{key}" } }.sort
  end

  class GoogleAuthMock
    def initialize(current_user)
      @current_user = current_user
    end

    def verify_jwt(_jwt)
      {
        'sub' => @current_user.uid,
        'name' => @current_user.name,
        'email' => @current_user.email
      }
    end

    def make_credentials(_scopes)
      nil
    end

    def fetch_access_token(_scope)
      'dummy_access_token'
    end
  end

  class CloudflareAccessMock
    def initialize(email)
      @email = email
    end

    def verify(token)
      { 'email' => @email } if token.present? && @email
    end
  end

  class IdentityPlatformMock
    def delete_account(_uid); end
  end

  class CloudflareImagesMock
    MOCK_ID = 'qoodish/test/mock-cf-id'

    def create_direct_upload
      { id: MOCK_ID, upload_url: "https://upload.example.com/#{MOCK_ID}" }
    end

    def upload_from_url(_source_url)
      "https://imagedelivery.net/mockhash/#{MOCK_ID}/public"
    end

    def delete(_image_id); end
  end
end
