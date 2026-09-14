class FeedCursor
  attr_reader :created_at, :id

  def initialize(timestamp, id = nil)
    @created_at = Time.zone.parse(timestamp.to_s)
    @id = id.presence&.to_i

    raise Exceptions::BadRequest if @created_at.nil?
  rescue ArgumentError
    raise Exceptions::BadRequest
  end

  def condition(table)
    if id
      ["#{table}.created_at < :created_at OR (#{table}.created_at = :created_at AND #{table}.id < :id)",
       { created_at: created_at, id: id }]
    else
      ["#{table}.created_at < ?", created_at]
    end
  end
end
