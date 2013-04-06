module Tracking
  class Client
    module SpecUtilityMethods
      def hour
        60 * 60
      end

      def day
        hour * 24
      end

      def week
        day * 7
      end

      def month
        day * 30
      end

      def year
        day * 365
      end

      def ago(time)
        Time.now - time
      end

      def in_the_future(time)
        Time.now + time
      end
    end
  end
end