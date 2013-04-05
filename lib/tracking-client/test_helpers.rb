module Tracking
  class Client
    class TestHelpers
      def self.delete_all_tracked_events!(client)
        raise "No!" if ENV['RACK_ENV'] == 'production'

        #cleanup keys from old tests
        redis = client.instance_variable_get('@minuteman').redis
        old_minuteman_keys = redis.keys('minuteman_*')
        redis.del old_minuteman_keys
      end
    end
  end
end