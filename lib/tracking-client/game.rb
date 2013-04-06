module Tracking
  class Client
    class Game
      TRACKING_KEY_PREFIX = "game-played"
      TRACKING_KEY_REGISTERED_SUFFIX = "registered-player"

      STARTING_YEAR = 2013
      VENUES = %w{facebook spiral-galaxy embedded}.map(&:to_sym)

      def initialize(client)
        @client = client
      end

      def track_logged_in_player(game_uuid, venue_name, player_uuid, options = {})
        @client.track_impression(registered_player_tracking_keys(game_uuid, venue_name), options)
      end

      def track_player(game_uuid, venue_name, options = {})
        @client.track_impression(tracking_keys(game_uuid, venue_name), options)
      end

      def insights(game_uuid, options = {})
        time = options[:time] || Time.now

        {
          overall: overall_insights(game_uuid, time)
        }.merge(venue_insights(game_uuid, time))
      end

      protected
      def tracking_keys(game_uuid, venue_name)
        keys = [
          "#{TRACKING_KEY_PREFIX}",
          "#{TRACKING_KEY_PREFIX}-#{game_uuid}",
          "#{TRACKING_KEY_PREFIX}-#{venue_name}",
          "#{TRACKING_KEY_PREFIX}-#{venue_name}-#{game_uuid}"
        ]
      end

      def registered_player_tracking_keys(game_uuid, venue_name)
        tracking_keys(game_uuid, venue_name).map {|k| "#{k}-#{TRACKING_KEY_REGISTERED_SUFFIX}"}
      end

      def overall_insights(game_uuid, time)
        insights_blocks_for("#{TRACKING_KEY_PREFIX}-#{game_uuid}", time)
      end

      def venue_insights(game_uuid, time)
        Hash[VENUES.map {|venue_name| [venue_name, insights_blocks_for("#{TRACKING_KEY_PREFIX}-#{venue_name}-#{game_uuid}", time)]}]
      end

      def insights_blocks_for(key, time)
        {
          anonymous: insights_block_for(key, time),
          logged_in: insights_block_for("#{key}-#{TRACKING_KEY_REGISTERED_SUFFIX}", time)
        }
      end

      def insights_block_for(key, time)
        day = 24 * 60 * 60

        query = []
        query << [:total, time: time]
        query << [:day, time: time]
        query << [:week, time: time]
        query << [:month, time: time]
        query << [:year, time: time]
        30.times.each do |i|
          query << [:day, time: time - (30 - i) * day]
        end
        impressions = @client.query_impression(key, query)

        {
          total: impressions.shift,
          today: impressions.shift,
          week: impressions.shift,
          month: impressions.shift,
          year: impressions.shift,
          rolling_30_days: impressions
        }
      end
    end
  end
end