require 'uuid'
require 'uuidtools'
require 'minuteman'

require "tracking-client/version"
require "tracking-client/error"
require "tracking-client/uuid_helpers"
require "tracking-client/query_result"

module Tracking
  class Client
    SUPPORTED_RESOLUTIONS = %w{year month week day hour}

    def initialize(redis_url)
      @minuteman = Minuteman.new(redis: {url: redis_url}, silent: suppress_errors?, time_spans: SUPPORTED_RESOLUTIONS)
    end

    def track(event, uuid, time = Time.now)
      @minuteman.track(event.to_s, UUIDHelpers.uuid_to_int(uuid), time)
    end

    def query(event, resolution, time = Time.now)
      raise Error.new("Resolution `#{resolution}` not supported!") unless resolution_supported?(resolution)

      result = @minuteman.send(resolution, event.to_s, time)
      QueryResult.new(result)
    end

    private
    def suppress_errors?
      ENV['RACK_ENV'] == 'production'
    end

    def resolution_supported?(resolution)
      SUPPORTED_RESOLUTIONS.include?(resolution.to_s)
    end
  end
end