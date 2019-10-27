if ENV['REDIS_HOST'].present?
  Redis.current = Redis.new(host: ENV['REDIS_HOST'])
end
