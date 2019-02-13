Redis.current = Redis.new(host: ENV['REDIS_HOST'])
Rails.logger.info("Currently connected to Redis: #{Redis.current.inspect}")
