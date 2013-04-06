module Tracking
  class Client
    class TestHelpers
      def self.delete_all_tracked_events!(client)
        raise "No!" if ENV['RACK_ENV'] == 'production'

        #cleanup keys from old tests
        redis = client.send(:redis)
        old_minuteman_keys = redis.keys('minuteman_*') || []
        redis.del old_minuteman_keys unless old_minuteman_keys.empty?

        old_qs_tracking_keys = redis.keys("#{TRACKING_KEY_PREFIX}*") || []
        redis.del old_qs_tracking_keys unless old_qs_tracking_keys.empty?
      end
    end
  end
end