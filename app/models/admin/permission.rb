module Admin
  class Permission
    READ_REPORTS = :read_reports
    DECIDE_REPORTS = :decide_reports
    MANAGE_STAFF = :manage_staff
    ALL = [READ_REPORTS, DECIDE_REPORTS, MANAGE_STAFF].freeze
  end
end
