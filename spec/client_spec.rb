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
    @client = Tracking::Client.new('redis://localhost:6379/')

    Tracking::Client::TestHelpers.delete_all_tracked_events!(@client)

    @entity1 = UUID.new.generate
    @entity2 = UUID.new.generate
    @entity3 = UUID.new.generate

    Timecop.freeze(Time.new(2013, 7, 15))
  end

  after do
    Timecop.return
  end

  it "should be able to track and query" do
    @client.track(:login, @entity1)
    @client.track(:login, @entity2)
    @client.track(:login, @entity3, in_the_future(1 * month))

    @client.track(:logout, @entity1, ago(1 * week))
    @client.track(:logout, @entity3, in_the_future(1 * week))

    logins_this_year = @client.query(:login, :year, Time.now)
    logins_this_year.length.must_equal 3
    logins_this_year.include_uuid?(@entity1).must_equal true
    logins_this_year.include_uuid?(@entity2).must_equal true
    logins_this_year.include_uuid?(@entity3).must_equal true

    logins_this_month = @client.query(:login, :month)
    logins_this_month.length.must_equal 2
    logins_this_year.include_uuid?(@entity1).must_equal true
    logins_this_year.include_uuid?(@entity2).must_equal true

    logouts_two_weeks_ago = @client.query(:logout, :week, ago(2 * week))
    logouts_two_weeks_ago.length.must_equal 0

    logouts_last_week = @client.query(:logout, :week, ago(1 * week))
    logouts_last_week.length.must_equal 1
    logouts_last_week.include_uuid?(@entity1).must_equal true

    logouts_this_month = @client.query(:logout, :month)
    logouts_this_month.length.must_equal(2)
    logouts_this_month.include_uuid?(@entity1).must_equal true
    logouts_this_month.include_uuid?(@entity3).must_equal true

    logouts_this_year = @client.query(:logout, :year)
    logouts_this_year.length.must_equal(2)
    logouts_this_year.include_uuid?(@entity1).must_equal true
    logouts_this_year.include_uuid?(@entity3).must_equal true
  end
end