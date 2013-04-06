module Tracking
  class Client
    class Impression
      def initialize(event, time)
        @event = event
        @time = time
      end

      def keys
        Client::SUPPORTED_RESOLUTIONS.map do |resolution|
          key_for(resolution)
        end
      end

      def key_for(resolution)
        "#{Client::TRACKING_KEY_PREFIX}#{@event}_#{time_key_for(resolution)}"
      end

      protected
      def time_key_for(resolution)
        send("time_key_for_#{resolution}")
      end

      def time_key_for_year
        "#{@time.year}"
      end

      def time_key_for_month
        "#{time_key_for_year}-#{@time.month}"
      end

      def time_key_for_week
        "#{time_key_for_month}-#{@time.strftime('%U')}"
      end

      def time_key_for_day
        "#{time_key_for_week}-#{@time.day}"
      end

      def time_key_for_hour
        "#{time_key_for_day}-#{@time.hour}"
      end
    end
  end
end