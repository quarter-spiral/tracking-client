# A client to track events

## Usage

The client allows you to either track *impressions* which are nothing more but stupid, incrementing counters for a given event. Or you can track *uniques* which do increment their count only once for any given event and UUID combination in any resolution.

The client understands different resolutions to query events for. So e.g. you can query for the number of times the ``sign_up`` event happened last week, or last month or just today. All available resolutions are:

```ruby
[:year, :month, :week, :day, :hour]
```

Be aware of the fact, that impressions and uniques are two completely different topic. Even if you use the same event name they will not interfere or mix at all.

### Setup

```ruby
redis_url = "redis://user:password@yourhost:15540"
client = Tracker::Client.new(redis_url)
```

**Important**: All tracking operations are non-blocking by default! You can override that on a per call basis or set the default to be blocking. All examples below are using a blocking client!

```ruby
client = Tracker::Client.new(redis_url, blocking: true)
```

### Impressions

#### Tracking

```ruby
# Track an impression that happened right now
client.track_impression(:user_signup)

# Track an impression at a given time
when_it_happened = Time.new(2012, 10, 1)
client.track_impression(:user_signup, time: when_it_happened)

# Tracking an impression explicitly non-blocking / blocking
client.track_impression(:user_signup, blocking: false) # => returns Thread, so you can call #join on it
client.track_impression(:user_signup, blocking: true)
```

#### Querying

```ruby
# All user signups this week
client.query_impression(:user_signup, :week)

# All user signups last year
client.query_impression(:user_signup, :year, time: Time.new(Time.now.year - 1))
```

### Uniqe events

E.g. unique page impression given a user. These do not add up but only count once for each user during any resolution.

#### Tracking

```ruby
# Track an event that happened right now
client.track_unique(:user_signup, uuid)

# Track an event at a given time
when_it_happened = Time.new(2012, 10, 1)
client.track_unique(:user_signup, uuid, time: when_it_happened)

# Tracking an unique explicitly non-blocking / blocking
client.track_unique(:user_signup, uuid, blocking: false) # => returns Thread, so you can call #join on it
client.track_unique(:user_signup, uuid, blocking: true)
```

#### Querying

```ruby
resolution = :month
when = Time.new(2012, 10)
result = client.query_unique(:user_signup, resolution, time: when)

# find out how many events occured during the timespan
result.length # => 1

# check if an event for a given UUID was tracked
result.include_uuid?(uuid) # => true / false

# query for signups this month (1st to last day in the last month)
client.query_unique(:user_signup, :month, time: Time.now)

# query for signups last year (1st of Jan to 31th of Dec)
last_year = Time.new(Time.now.year - 1)
client.query_unique(:user_signup, :year, time: last_year)
```
