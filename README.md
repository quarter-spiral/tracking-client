# A client to track events

## Usage

### Setup

```ruby
redis_url = "redis://user:password@yourhost:15540"
client = Tracker::Client.new(redis_url)
```

### Important

Impressions and unique events do not mix at all. They are completely separated things.

### Impressions

E.g. page impressions. These always just add up. Think of them as of a stupid incrementing counter.

#### Tracking

```ruby
# Track an impression that happened right now
client.track_impression(:user_signup)

# Track an impression at a given time
when_it_happened = Time.new(2012, 10, 1)
client.track_impression(:user_signup, when_it_happened)
```

#### Querying

```ruby
# All user signups this week
client.query_impression(:user_signup, :week)

# All user signups last year
client.query_impression(:user_signup, :year, Time.new(Time.now.year - 1))
```

### Uniqe events

E.g. unique page impression given a user. These do not add up but only count once for each user during any resolution.

#### Tracking

```ruby
# Track an event that happened right now
client.track_unique(:user_signup, uuid)

# Track an event at a given time
when_it_happened = Time.new(2012, 10, 1)
client.track_unique(:user_signup, uuid, when_it_happened)
```

#### Querying

```ruby
resolution = :month
when = Time.new(2012, 10)
result = client.query_unique(:user_signup, resolution, when)

# find out how many events occured during the timespan
result.length # => 1

# check if an event for a given UUID was tracked
result.include_uuid?(uuid) # => true / false

# query for signups this month (1st to last day in the last month)
client.query_unique(:user_signup, :month, Time.now)

# query for signups last year (1st of Jan to 31th of Dec)
last_year = Time.new(Time.now.year - 1)
client.query_unique(:user_signup, :year, last_year)
```

### Resolutions

Possible resolutions are:
```ruby
[:year, :month, :week, :day, :hour]
```