require_relative './spec_helper'

require 'timecop'

GAME_IMPRESSIONS_KEY_PREFIX = 'game-played'

class Array
  def sum
    inject(0) {|a,e| a + e}
  end
end

def game_impression_key(suffix, options)
  registered = options[:registered]
  "#{GAME_IMPRESSIONS_KEY_PREFIX}#{suffix}#{registered ? '-registered-player' : ''}"
end

def must_have_total_plays(count, options = {})
  @client.query_impression(game_impression_key(nil, options), :year).must_equal count
end

def must_have_game_plays(game, count, options = {})
  @client.query_impression(game_impression_key("-#{game}", options), :year).must_equal count
end

def must_have_venue_plays(venue, count, options = {})
  @client.query_impression(game_impression_key("-#{venue}", options), :year).must_equal count
end

def must_have_venue_game_plays(venue, game, count, options = {})
  @client.query_impression(game_impression_key("-#{venue}-#{game}", options), :year).must_equal count
end

def track_players(plays, game, venue, player = nil)
  now = Time.now
  day = 24 * 60 * 60

  i = plays.size
  plays.each do |count|
    i -= 1
    count.times do
      if player
        @client.game.track_logged_in_player(game, venue, player, time: now - (i * day))
      else
        @client.game.track_player(game, venue, time: now - (i * day))
      end
    end
  end
end

describe Tracking::Client::Game do
  before do
    @client = Tracking::Client.new('redis://localhost:6379/', blocking: true)

    Tracking::Client::TestHelpers.delete_all_tracked_events!(@client)

    @game = UUID.new.generate
    @game2 = UUID.new.generate

    Timecop.freeze(Time.new(2013, 7, 15, 1, 30))
  end

  after do
    Timecop.return
  end

  it "only tracks keys for unregistered players when tracking unregistered players" do
    @client.game.track_player(@game, "facebook")
    @client.game.track_player(@game, "facebook")
    @client.game.track_player(@game, "spiral-galaxy")

    @client.game.track_player(@game2, "facebook")

    must_have_total_plays(4)
    must_have_game_plays(@game, 3)
    must_have_game_plays(@game2, 1)
    must_have_venue_plays('facebook', 3)
    must_have_venue_plays('spiral-galaxy', 1)
    must_have_venue_game_plays('facebook', @game, 2)
    must_have_venue_game_plays('spiral-galaxy', @game, 1)
    must_have_venue_game_plays('facebook', @game2, 1)
    must_have_venue_game_plays('spiral-galaxy', @game2, 0)

    must_have_total_plays(0, registered: true)
    must_have_game_plays(@game, 0, registered: true)
    must_have_game_plays(@game2, 0, registered: true)
    must_have_venue_plays('facebook', 0, registered: true)
    must_have_venue_plays('spiral-galaxy', 0, registered: true)
    must_have_venue_game_plays('facebook', @game, 0, registered: true)
    must_have_venue_game_plays('spiral-galaxy', @game, 0, registered: true)
    must_have_venue_game_plays('facebook', @game2, 0, registered: true)
    must_have_venue_game_plays('spiral-galaxy', @game2, 0, registered: true)
  end

  it "only tracks keys for registered players when tracking registered players" do
    fake_player = UUID.new.generate
    @client.game.track_logged_in_player(@game, "facebook", fake_player)
    @client.game.track_logged_in_player(@game, "facebook", fake_player)
    @client.game.track_logged_in_player(@game, "spiral-galaxy", fake_player)

    @client.game.track_logged_in_player(@game2, "facebook", fake_player)

    must_have_total_plays(0)
    must_have_game_plays(@game, 0)
    must_have_game_plays(@game2, 0)
    must_have_venue_plays('facebook', 0)
    must_have_venue_plays('spiral-galaxy', 0)
    must_have_venue_game_plays('facebook', @game, 0)
    must_have_venue_game_plays('spiral-galaxy', @game, 0)
    must_have_venue_game_plays('facebook', @game2, 0)
    must_have_venue_game_plays('spiral-galaxy', @game2, 0)

    must_have_total_plays(4, registered: true)
    must_have_game_plays(@game, 3, registered: true)
    must_have_game_plays(@game2, 1, registered: true)
    must_have_venue_plays('facebook', 3, registered: true)
    must_have_venue_plays('spiral-galaxy', 1, registered: true)
    must_have_venue_game_plays('facebook', @game, 2, registered: true)
    must_have_venue_game_plays('spiral-galaxy', @game, 1, registered: true)
    must_have_venue_game_plays('facebook', @game2, 1, registered: true)
    must_have_venue_game_plays('spiral-galaxy', @game2, 0, registered: true)
  end

  it "can return basic insights on a game" do
    fake_player = UUID.new.generate

    plays_on_facebook = 40.times.map {rand(10)}
    plays_on_spiral_galaxy = 40.times.map {rand(10)}
    plays_on_embedded = 40.times.map {rand(10)}

    track_players(plays_on_facebook, @game, 'facebook')
    track_players(plays_on_spiral_galaxy, @game, 'spiral-galaxy')
    track_players(plays_on_embedded, @game, 'embedded')

    registered_plays_on_facebook = 40.times.map {rand(10)}
    registered_plays_on_spiral_galaxy = 40.times.map {rand(10)}
    registered_plays_on_embedded = 40.times.map {rand(10)}

    track_players(registered_plays_on_facebook, @game, 'facebook', fake_player)
    track_players(registered_plays_on_spiral_galaxy, @game, 'spiral-galaxy', fake_player)
    track_players(registered_plays_on_embedded, @game, 'embedded', fake_player)

    insights = @client.game.insights(@game)

    insights.keys.size.must_equal 4
    insights[:overall].must_equal(
      anonymous: {
        total: plays_on_facebook.sum + plays_on_spiral_galaxy.sum + plays_on_embedded.sum,
        today: plays_on_facebook.last + plays_on_spiral_galaxy.last + plays_on_embedded.last,
        week: plays_on_facebook[-2..-1].sum + plays_on_spiral_galaxy[-2..-1].sum + plays_on_embedded[-2..-1].sum,
        month: plays_on_facebook[-15..-1].sum + plays_on_spiral_galaxy[-15..-1].sum + plays_on_embedded[-15..-1].sum,
        year: plays_on_facebook.sum + plays_on_spiral_galaxy.sum + plays_on_embedded.sum,
        rolling_30_days: 30.times.map {|i| plays_on_facebook[-31 + i] + plays_on_spiral_galaxy[-31 + i] + plays_on_embedded[-31 + i]}
      },
      logged_in: {
        total: registered_plays_on_facebook.sum + registered_plays_on_spiral_galaxy.sum + registered_plays_on_embedded.sum,
        today: registered_plays_on_facebook.last + registered_plays_on_spiral_galaxy.last + registered_plays_on_embedded.last,
        week: registered_plays_on_facebook[-2..-1].sum + registered_plays_on_spiral_galaxy[-2..-1].sum + registered_plays_on_embedded[-2..-1].sum,
        month: registered_plays_on_facebook[-15..-1].sum + registered_plays_on_spiral_galaxy[-15..-1].sum + registered_plays_on_embedded[-15..-1].sum,
        year: registered_plays_on_facebook.sum + registered_plays_on_spiral_galaxy.sum + registered_plays_on_embedded.sum,
        rolling_30_days: 30.times.map {|i| registered_plays_on_facebook[-31 + i] + registered_plays_on_spiral_galaxy[-31 + i] + registered_plays_on_embedded[-31 + i]}
      }
    )
    insights[:"spiral-galaxy"].must_equal(
      anonymous: {
        total: plays_on_spiral_galaxy.sum,
        today: plays_on_spiral_galaxy.last,
        week: plays_on_spiral_galaxy[-2..-1].sum,
        month: plays_on_spiral_galaxy[-15..-1].sum,
        year: plays_on_spiral_galaxy.sum,
        rolling_30_days: 30.times.map {|i| plays_on_spiral_galaxy[-31 + i]}
      },
      logged_in: {
        total: registered_plays_on_spiral_galaxy.sum,
        today: registered_plays_on_spiral_galaxy.last,
        week: registered_plays_on_spiral_galaxy[-2..-1].sum,
        month: registered_plays_on_spiral_galaxy[-15..-1].sum,
        year: registered_plays_on_spiral_galaxy.sum,
        rolling_30_days: 30.times.map {|i| registered_plays_on_spiral_galaxy[-31 + i]}
      }
    )

    insights[:facebook].must_equal(
      anonymous: {
        total: plays_on_facebook.sum,
        today: plays_on_facebook.last,
        week: plays_on_facebook[-2..-1].sum,
        month: plays_on_facebook[-15..-1].sum,
        year: plays_on_facebook.sum,
        rolling_30_days: 30.times.map {|i| plays_on_facebook[-31 + i]}
      },
      logged_in: {
        total: registered_plays_on_facebook.sum,
        today: registered_plays_on_facebook.last,
        week: registered_plays_on_facebook[-2..-1].sum,
        month: registered_plays_on_facebook[-15..-1].sum,
        year: registered_plays_on_facebook.sum,
        rolling_30_days: 30.times.map {|i| registered_plays_on_facebook[-31 + i]}
      }
    )
    insights[:embedded].must_equal(
      anonymous: {
        total: plays_on_embedded.sum,
        today: plays_on_embedded.last,
        week: plays_on_embedded[-2..-1].sum,
        month: plays_on_embedded[-15..-1].sum,
        year: plays_on_embedded.sum,
        rolling_30_days: 30.times.map {|i| plays_on_embedded[-31 + i]}
      },
      logged_in: {
        total: registered_plays_on_embedded.sum,
        today: registered_plays_on_embedded.last,
        week: registered_plays_on_embedded[-2..-1].sum,
        month: registered_plays_on_embedded[-15..-1].sum,
        year: registered_plays_on_embedded.sum,
        rolling_30_days: 30.times.map {|i| registered_plays_on_embedded[-31 + i]}
      }
    )
  end
end