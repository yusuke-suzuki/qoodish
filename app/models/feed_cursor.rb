class FeedCursor
  attr_reader :created_at, :id

  def self.decode(token)
    timestamp, id = Base64.urlsafe_decode64(token.to_s).split(',', 2)
    raise Exceptions::BadRequest unless id&.match?(/\A[1-9]\d*\z/)

    new(timestamp, id)
  rescue ArgumentError
    raise Exceptions::BadRequest
  end

  def self.next_token(records, per_page)
    page = records.to_a
    new(page.last.created_at.iso8601(6), page.last.id).encode if page.size == per_page
  end

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

  def encode
    Base64.urlsafe_encode64("#{created_at.iso8601(6)},#{id}", padding: false)
  end
end
