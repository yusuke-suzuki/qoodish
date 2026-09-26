ActiveRecord::Base.transaction do
  administrator = Admin::Role.find_or_create_by!(name: 'administrator') do |role|
    role.description = 'Everything the admin API allows'
  end
  Admin::Permission::ALL.each { |permission| administrator.permit!(permission) }

  moderator = Admin::Role.find_or_create_by!(name: 'moderator') do |role|
    role.description = 'Reads reports and decides them'
  end
  [Admin::Permission::READ_REPORTS, Admin::Permission::DECIDE_REPORTS].each { |permission| moderator.permit!(permission) }
end

Rails.logger.info("Admin roles: #{Admin::Role.order(:name).pluck(:name).join(', ')}")
