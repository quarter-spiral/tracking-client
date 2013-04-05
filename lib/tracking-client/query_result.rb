module Tracking
  class Client
    class QueryResult < BasicObject
      def initialize(result)
        @result = result
      end

      def include_uuid?(uuid)
        @result.include?(UUIDHelpers.uuid_to_int(uuid))
      end

      private
      def method_missing(method, *args, &block)
        @result.send(method, *args, &block)
      end
    end
  end
end