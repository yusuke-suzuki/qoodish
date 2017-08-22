namespace = [Rails.application.class.parent_name, Rails.env].join ':'
Redis.current = Redis::Namespace.new(namespace, redis: Redis.new(host: ENV['REDIS_HOST']))
Rails.logger.info("Currently connected to Redis: #{Redis.current.inspect}")
