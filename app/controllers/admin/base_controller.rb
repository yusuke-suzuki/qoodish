module Admin
  class BaseController < ApplicationController
    ACCESS_JWT_HEADER = 'Cf-Access-Jwt-Assertion'.freeze

    class_attribute :action_permissions, instance_writer: false, default: {}

    before_action :authenticate_staff_member!
    before_action :authorize_staff_member!

    def self.requires_permission(permission, only:)
      self.action_permissions = action_permissions.merge(Array(only).to_h { |action| [action.to_s, permission] })
    end

    private

    attr_reader :current_staff_member

    def authenticate_staff_member!
      email = CloudflareAccess.new.verify(request.headers[ACCESS_JWT_HEADER])&.dig('email')
      raise Exceptions::Unauthorized if email.blank?

      @current_staff_member = StaffMember.active.find_by(email: email)
    end

    def authorize_staff_member!
      permission = action_permissions[action_name]

      raise Exceptions::Forbidden unless permission && current_staff_member&.can?(permission)
    end

    def other_staff_member(id)
      staff_member = StaffMember.find(id)
      raise Exceptions::UnprocessableContent, I18n.t('messages.api.staff_member_self_change') if staff_member == current_staff_member

      staff_member
    end
  end
end
