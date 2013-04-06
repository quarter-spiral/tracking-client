require 'uuid'
require 'uuidtools'
require 'minuteman'

require "tracking-client/version"
require "tracking-client/error"
require "tracking-client/uuid_helpers"
require "tracking-client/query_result"
require "tracking-client/impression"

module Tracking
  class Client
    SUPPORTED_RESOLUTIONS = %w{year month week day hour}
    TRACKING_KEY_PREFIX = "qs_tracking_"

    def initialize(redis_url)
      @minuteman = Minuteman.new(redis: {url: redis_url, driver: :hiredis}, silent: suppress_errors?, time_spans: SUPPORTED_RESOLUTIONS)
    end

    def track_unique(event, uuid, time = Time.now)
      @minuteman.track(event.to_s, UUIDHelpers.uuid_to_int(uuid), time)
    end

    def query_unique(event, resolution, time = Time.now)
      raise Error.new("Resolution `#{resolution}` not supported!") unless resolution_supported?(resolution)

      result = @minuteman.send(resolution, event.to_s, time)
      QueryResult.new(result)
    end

    def track_impression(event, time = Time.now)
      Impression.new(event, time).keys.map do |key|
        Thread.new {redis.incr key}
      end.each {|t| t.join}
    end

    def query_impression(event, resolution, time = Time.now)
      redis.get(Impression.new(event, time).key_for(resolution)).to_i
    end

    private
    def suppress_errors?
      ENV['RACK_ENV'] == 'production'
    end

    def resolution_supported?(resolution)
      SUPPORTED_RESOLUTIONS.include?(resolution.to_s)
    end

    def redis
      @minuteman.redis
    end
  end
end