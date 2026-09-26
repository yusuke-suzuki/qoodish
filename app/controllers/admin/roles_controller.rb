module Admin
  class RolesController < BaseController
    requires_permission Permission::MANAGE_STAFF, only: :index

    def index
      @roles = Role.preload(:role_permissions).order(:name)
    end
  end
end
