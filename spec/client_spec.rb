require_relative './spec_helper'

require 'timecop'

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

describe Tracking::Client do
  before do
    @client = Tracking::Client.new('redis://localhost:6379/', blocking: true)

    Tracking::Client::TestHelpers.delete_all_tracked_events!(@client)

    @entity1 = UUID.new.generate
    @entity2 = UUID.new.generate
    @entity3 = UUID.new.generate

    Timecop.freeze(Time.new(2013, 7, 15, 1, 30))
  end

  after do
    Timecop.return
  end

  it "should be able to track and query unique events" do
    @client.track_unique(:login, @entity1)
    @client.track_unique(:login, @entity2)
    @client.track_unique(:login, @entity3, time: in_the_future(1 * month))

    @client.track_unique(:logout, @entity1, time: ago(1 * week))
    @client.track_unique(:logout, @entity3, time: in_the_future(1 * week))

    logins_this_year = @client.query_unique(:login, :year, time: Time.now)
    logins_this_year.length.must_equal 3
    logins_this_year.include_uuid?(@entity1).must_equal true
    logins_this_year.include_uuid?(@entity2).must_equal true
    logins_this_year.include_uuid?(@entity3).must_equal true

    logins_this_month = @client.query_unique(:login, :month)
    logins_this_month.length.must_equal 2
    logins_this_year.include_uuid?(@entity1).must_equal true
    logins_this_year.include_uuid?(@entity2).must_equal true

    logouts_two_weeks_ago = @client.query_unique(:logout, :week, time: ago(2 * week))
    logouts_two_weeks_ago.length.must_equal 0

    logouts_last_week = @client.query_unique(:logout, :week, time: ago(1 * week))
    logouts_last_week.length.must_equal 1
    logouts_last_week.include_uuid?(@entity1).must_equal true

    logouts_this_month = @client.query_unique(:logout, :month)
    logouts_this_month.length.must_equal(2)
    logouts_this_month.include_uuid?(@entity1).must_equal true
    logouts_this_month.include_uuid?(@entity3).must_equal true

    logouts_this_year = @client.query_unique(:logout, :year)
    logouts_this_year.length.must_equal(2)
    logouts_this_year.include_uuid?(@entity1).must_equal true
    logouts_this_year.include_uuid?(@entity3).must_equal true
  end

  it "can track impressions" do
    @client.track_impression(:login, time: ago(1 * year))

    @client.track_impression(:login, time: ago(2 * month))

    @client.track_impression(:login, time: ago(1 * week))
    @client.track_impression(:login, time: ago(1 * week))

    @client.track_impression(:login, time: ago(1 * day))

    @client.track_impression(:login)

    # watch out, it's a logout!
    @client.track_impression(:logout)

    @client.track_impression(:login, time: ago(2 * hour))
    @client.track_impression(:login, time: ago(1 * hour))

    @client.track_impression(:login, time: in_the_future(1 * week))

    # this year
    @client.query_impression(:login, :year).must_equal 8
    # last year
    @client.query_impression(:login, :year, time: ago(8 * month)).must_equal 1
    # this month
    @client.query_impression(:login, :month).must_equal 7
    # two month ago
    @client.query_impression(:login, :month, time: ago(2 * month)).must_equal 1
    # this week
    @client.query_impression(:login, :week).must_equal 4
    # last week
    @client.query_impression(:login, :week, time: ago(1 * week)).must_equal 2
    # today
    @client.query_impression(:login, :day).must_equal 2
    # yesterday
    @client.query_impression(:login, :day, time: ago(1 * day)).must_equal 2
    # next week
    @client.query_impression(:login, :week, time: in_the_future(1 * week)).must_equal 1

    # two years ago
    @client.query_impression(:login, :week, time: ago(2 * year)).must_equal 0
  end

  it "can track multiple impressions" do
    @client.track_impression([:login, :logout])
    @client.query_impression(:login, :year).must_equal 1
    @client.query_impression(:logout, :year).must_equal 1
  end

  it "can track multiple events" do
    @client.track_unique([:login, :logout], @entity1)
    logins = @client.query_unique(:login, :year)
    logins.length.must_equal 1
    logins.include_uuid?(@entity1).must_equal true

    logouts = @client.query_unique(:logout, :year)
    logouts.length.must_equal 1
    logouts.include_uuid?(@entity1).must_equal true
  end

  it "can track impressions asynchronously" do
    lots_of_events = 10000.times.map {"event-#{rand(10000)}"}
    lots_of_events << 'login'
    tracking_thread = @client.track_impression(:login, blocking: false)

    @client.query_impression(:login, :year).must_equal 0
    tracking_thread.join
    @client.query_impression(:login, :year).must_equal 1
  end

  it "can track uniques asynchronously" do
    blocking_event = 'login'
    class << blocking_event
      attr_accessor :block_to_s

      alias raw_to_s to_s
      def to_s
        while @block_to_s; sleep 0.0001; end
        raw_to_s
      end
    end
    blocking_event.block_to_s = true

    tracking_thread = @client.track_unique(blocking_event, @entity1, blocking: false)

    @client.query_unique(:login, :year).length.must_equal 0
    blocking_event.block_to_s = false
    tracking_thread.join
    @client.query_unique(:login, :year).length.must_equal 1
  end
end