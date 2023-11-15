require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/autorun'

class ActiveSupport::TestCase
  fixtures :all

  def stub_google_auth(current_user, &block)
    GoogleAuth.stub :new, GoogleAuthMock.new(current_user), &block
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
  end
end
