require 'uuid'
require 'uuidtools'
require 'minuteman'

require "tracking-client/version"
require "tracking-client/error"
require "tracking-client/uuid_helpers"
require "tracking-client/query_result"
require "tracking-client/impression"
require "tracking-client/game"

module Tracking
  class Client
    SUPPORTED_RESOLUTIONS = %w{total year month week day hour}
    TRACKING_KEY_PREFIX = "qs_tracking_"

    attr_reader :game

    def initialize(redis_url, options = {})
      @minuteman = Minuteman.new(redis: {url: redis_url, driver: :hiredis}, silent: suppress_errors?, time_spans: SUPPORTED_RESOLUTIONS)
      @options = options
      @game = Game.new(self)
    end

    def track_unique(events, uuids, options = {})
      time = options[:time] || Time.now
      uuids = Array(uuids)
      action = Proc.new {
        Array(events).map do |event|
          @minuteman.track(event.to_s, uuids.map {|uuid| UUIDHelpers.uuid_to_int(uuid)}, time)
        end
      }

      run_action(action, options)
    end

    def query_unique(event, resolution, options = {})
      time = options[:time] || Time.now
      raise Error.new("Resolution `#{resolution}` not supported!") unless resolution_supported?(resolution)

      result = @minuteman.send(resolution, event.to_s, time)
      QueryResult.new(result)
    end

    def track_impression(events, options = {})
      time = options[:time] || Time.now

      action = Proc.new do
        Array(events).map do |event|
          Thread.new do
            Impression.new(event, time).keys.map do |key|
              Thread.new {redis.incr key}
            end.each(&:join)
          end
        end.each(&:join)
      end

      run_action(action, options)
    end

    def query_impression(event, resolutions, options = {})
      now = Time.now
      if resolutions.kind_of?(Array)
        keys = resolutions.map do |resolution, options|
          time = (options || {})[:time] || now
          Impression.new(event, time).key_for(resolution)
        end
        redis.mget(keys).map(&:to_i)
      else
        time = options[:time] || now
        redis.get(Impression.new(event, time).key_for(resolutions)).to_i
      end
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

    def run_action(action, options)
      if synchronous?(options)
        action.call
      else
        Thread.new(action) {|action| action.call}
      end
    end

    def synchronous?(options)
      options.has_key?(:blocking) ? options[:blocking] : @options[:blocking]
    end
  end
end