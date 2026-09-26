module Admin
  class Permission
    READ_REPORTS = :read_reports
    DECIDE_REPORTS = :decide_reports
    ALL = [READ_REPORTS, DECIDE_REPORTS].freeze
  end
end
