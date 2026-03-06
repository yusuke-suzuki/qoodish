# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/autorun'

class ActiveSupport::TestCase
  fixtures :all

  def stub_google_auth(current_user, &block)
    GoogleAuth.stub :new, GoogleAuthMock.new(current_user), &block
  end

  def stub_identity_platform(&block)
    IdentityPlatform.stub :new, IdentityPlatformMock.new, &block
  end

  def stub_cloud_storage(&block)
    Google::Cloud::Storage.stub :new, CloudStorageMock.new, &block
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

  class CloudStorageMock
    def bucket(_name)
      BucketMock.new
    end

    class BucketMock
      def file(_path)
        nil
      end
    end
  end
end
