# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/autorun'

ENV['CLOUDFLARE_ACCOUNT_ID'] ||= 'test-account'
ENV['CLOUDFLARE_IMAGES_ACCOUNT_HASH'] ||= 'mockhash'
ENV['CLOUDFLARE_IMAGES_API_TOKEN'] ||= 'test-token'

class ActiveSupport::TestCase
  fixtures :all

  def stub_google_auth(current_user, &block)
    GoogleAuth.stub :new, GoogleAuthMock.new(current_user), &block
  end

  def stub_identity_platform(&block)
    IdentityPlatform.stub :new, IdentityPlatformMock.new, &block
  end

  def stub_cloudflare_images(&block)
    Cloudflare::Images.stub :new, CloudflareImagesMock.new, &block
  end

  class GoogleAuthMock
    def initialize(current_user)
      @current_user = current_user
    end

    def verify_jwt(_jwt)
      {
        'sub' => @current_user.uid,
        'name' => @current_user.name
      }
    end

    def make_credentials(_scopes)
      nil
    end

    def fetch_access_token(_scope)
      'dummy_access_token'
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
