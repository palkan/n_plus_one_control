## Building a custom collector

By default, `n_plus_one_control` checks for N+1 database calls, but what if we want to make sure, for example, that we make constant number of HTTP calls? For this purpose, we can build a custom Collector class.

Let's say, we have a Rails application, that has some client:
```ruby
class ExternalClient
  def self.request(url)
    # call http, process the response, etc.
  end
end
```

First thing we need to do is to add a notification that we perfom a request:
```ruby
class ExternalClient
  def self.request(url)
    ActiveSupport::Notifications.instrument('external_client.http', url: url)
    # call http, process the response, etc.
  end
end
```

Now, in tests, we can subscribe to this event and count, how many times http was called.

To do so, we define a new class:
```ruby
class HTTPCollector < NPlusOneControl::Collectors::Base
  self.key = :http # This key we will be using later in tests
  self.name = 'HTTP' # Optional; used for error message. If omitted, will default to `key.to_s.upcase`
  self.event = 'external_client.http' # This is the event we created above
  # You can also make event dynamic by passing a proc here, like:
  # self.event = -> { fetch_event_name }

  def callback(*, payload) # See ActiveSupport::Notifications docs to learn about other params
    # Put something to `@queries`; In matchers, we rely on its size.
    @queries << payload[:url]
  end
end

NPlusOneControl::CollectorsRegistry.register(HTTPCollector)
```

Now, let's say we have some model, that can call the client to get some data:
```ruby
class Record < ApplicationRecord
  def externa_data
    @data ||= ExternalClient.request("domain.com/record?ids=#{id}")
  end

  def cache_data(data)
    @data = data
  end
end
```

Whenever we have several record ids and need to get that external data, we have several options:
```ruby
# 1. N+1
Record.find(ids).map(external_data)

# 2. No N+1
data = ExternalClient.request("domain.com/record?ids=#{ids.join(',')}") # Yes, quite a simplified example, but still
Record.find(ids).each { |record| record.cache_data(data.fetch(record.id)) }
```

Of course, we prefer the second way without N+1 HTTP requests. Now, to make sure we use it, we can write a test:

```ruby
# RSpec
context "N+1", :n_plus_one do
  specify do
    expect { some_code_triggering_possible_n_plus_one }.to perform_constant_number_of_queries.to(:http)
  end
end

# Minitiest
def test_no_n_plus_one_http
  assert_perform_constant_number_of_queries(collectors: :http) do
    some_code_triggering_possible_n_plus_one
  end
end
```

We may also extend this test to check _both_ HTTP _and_ DB queries:
```ruby
# RSpec
context "N+1", :n_plus_one do
  specify do
    expect { some_code_triggering_possible_n_plus_one }.to perform_constant_number_of_queries.to(:db, :http)
  end
end

# Minitiest
def test_no_n_plus_one_http
  assert_perform_constant_number_of_queries(collectors: %i[http db]) do
    some_code_triggering_possible_n_plus_one
  end
end
```

**NOTE**: this also works with `perform_linear_number_of_queries` and `assert_perform_linear_number_of_queries`.

### Error message

By default, your custom collector will show a very minimal information in error message, only amount of calls for each N. You can enrich it by redefining `failure_message` method in the collector class:
```ruby
class HTTPCollector
  def self.failure_message(_, queries)
    msg = super

    if NPlusOneControl.verbose
      queries.each do |(scale, data)|
        msg << "Queries for N=#{scale}\n"

        # `data[:http]` contains everything we were putting to `@queries` in the `callback` method for the given scale.
        # In our case, it is URLs that we request
        msg << data[:http].map { |url| "  #{url}\n" }.join.to_s
      end
    end

    msg
  end
end
```

With this enhancement, error message will also contain all the URLs we requested for every scale factor.
