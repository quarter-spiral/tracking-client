module Tracking
  class Client
    class UUIDHelpers
      def self.uuid_to_int(uuid)
        UUIDTools::UUID.parse(uuid).hash
      end
    end
  end
end