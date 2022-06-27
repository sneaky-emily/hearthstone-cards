require 'redis'
# Common methods to deal with Redis cache with soft-failure mechanisms
class CacheHelper
  # Enable redis if it's URL is set as an environmental variable
  REDIS_URL = ENV['REDIS_URL'] || false
  REDIS = Redis.new(url: REDIS_URL)

  def initialize
    return unless REDIS_URL # If REDIS_URL is not defined, do not continue

    begin
      REDIS.ping
    rescue Redis::ConnectionError, Errno::ECONNREFUSED, Redis::CannotConnectError
      puts '################################################################################################'
      puts '# There was an error while attempting to connect to Redis, continuing without a cache          #'
      puts '################################################################################################'
    end
  end

  class << self
    def enabled?
      REDIS_URL && REDIS.connected?
    end

    def exists?(slug, params = '')
      REDIS.exists?(slug + params.to_s)
    end

    def get(slug, params = '')
      REDIS.get(slug + params.to_s) # To handle pagination of results/differing request parameters
    end

    def set(slug, data, ttl, params = '')
      REDIS.set(slug + params.to_s, data, ex: ttl)
    end

    def del(slug, params = '')
      REDIS.del(slug + params.to_s)
    end
  end
end
