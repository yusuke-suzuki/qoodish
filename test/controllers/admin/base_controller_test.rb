require 'test_helper'

class Admin::BaseControllerTest < ActiveSupport::TestCase
  test 'every admin action declares the permission it requires' do
    admin_routes = Rails.application.routes.routes.select { |route| route.defaults[:controller]&.start_with?('admin/') }

    assert_not_empty admin_routes

    admin_routes.each do |route|
      controller = "#{route.defaults[:controller]}_controller".classify.constantize
      action = route.defaults[:action]

      assert_includes controller.action_permissions.keys, action, "#{controller.name}##{action} declares no permission"
      assert_includes Admin::Permission::ALL, controller.action_permissions[action],
                      "#{controller.name}##{action} declares an unknown permission"
    end
  end
end
