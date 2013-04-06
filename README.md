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

You can also query for multiple event/time combinations at once:

```ruby
query = [
  [:day],
  [:day, Time.now - (24 * 60 * 60)], # yesterday
  [:year, Time.new(Time.now.year - 1)], # last year
]
client.query_impression(:user_signup, query) # => [3, 5, 107]
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

### Game specific tracking

#### Track an anonymous player

```ruby
client.game.track_player(game_uuid, "spiral-galaxy")

# Track at a specific point in time
last_year = Time.new(Time.now.year - 1)
client.game.track_player(game_uuid, "spiral-galaxy", time: last_year)
```

#### Track a logged in player

```ruby
client.game.track_logged_in_player(game_uuid, "spiral-galaxy")

# Track at a specific point in time
last_year = Time.new(Time.now.year - 1)
client.game.track_logged_in_player(game_uuid, "spiral-galaxy", time: last_year)
```

#### Retrieve insights on a game

```ruby
client.game.insights(game_uuid)

# get them for a specific point in time
last_year = Time.new(Time.now.year - 1)
client.game.insights(game_uuid, time: last_year)
```

The ``#insights`` method returns a hash with a block for each venue and one for overall numbers. Each of those blocks have two keys, ``:anonymous`` (for numbers on not logged in players) and ``:logged_in`` (for numbers of logged in players). That could look like this:

```ruby
{
  overall: {
    anonymous: {
      …
    },
    logged_in: {
      …
    }
  },
  facebook: {
    anonymous: {
      …
    },
    logged_in: {
      …
    }
  }
}
```

Each of the inner blocks now looks like this:

```ruby
{
  total: 13245,
  today: 45,
  week: 301,
  month: 720,
  year: 6329,
  rolling_30_days: [76,13,46,23,24,23,63,…]
}
```

with data on the total impressions, the impressions today so far, during the current week, the current month and the current year. In addition to that it gives you the impressions over the last 30 days day by day. The first element in that array is the number of impressions 31 days ago. The last element is the number of impressions yesterday.