# A client to track events

## Usage

### Setup

```ruby
redis_url = "redis://user:password@yourhost:15540"
client = Tracker::Client.new(redis_url)
```

### Track an event

```ruby
# Track an event that happened right now
client.track(:user_signup, uuid)

# Track an event at a given time
when_it_happened = Time.new(2012, 10, 1)
client.track(:user_signup, uuid, when_it_happened)
```

### Query for events

```ruby
resolution = :month
when = Time.new(2012, 10)
result = client.query(:user_signup, resolution, when)

# find out how many events occured during the timespan
result.length # => 1

# check if an event for a given UUID was tracked
result.include_uuid?(uuid) # => true / false

# query for signups this month (1st to last day in the last month)
client.query(:user_signup, :month, Time.now)

# query for signups last year (1st of Jan to 31th of Dec)
last_year = Time.new(Time.now.year - 1)
client.query(:user_signup, :year, last_year)
```

#### Resolution

Possible resolutions are:
```ruby
[:year, :month, :week, :day, :hour]
```