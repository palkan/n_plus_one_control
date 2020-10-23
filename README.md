[![Gem Version](https://badge.fury.io/rb/n_plus_one_control.svg)](https://rubygems.org/gems/n_plus_one_control)
![Build](https://github.com/palkan/n_plus_one_control/workflows/Build/badge.svg)

# N + 1 Control

RSpec and Minitest matchers to prevent the N+1 queries problem.

<img src="https://s3.amazonaws.com/anycable/n_plus_one_control.png" alt="Example output" width="553px">

### Why yet another gem to assert DB queries?

Unlike other libraries (such as [db-query-matchers](https://github.com/brigade/db-query-matchers), [rspec-sqlimit](https://github.com/nepalez/rspec-sqlimit), etc), with `n_plus_one_control` you don't have to specify exact expectations to control your code behaviour (e.g. `expect { subject }.to query(2).times`).

Such expectations are rather hard to maintain, 'cause there is a big chance of adding more queries, not related to the system under test.

NPlusOneControl works differently. It evaluates the code under consideration several times with different scale factors to make sure that the number of DB queries behaves as expected (i.e. O(1) instead of O(N)).

So, it's for _performance_ testing and not _feature_ testing.

### Why not just use [`bullet`](https://github.com/flyerhzm/bullet)?

Of course, it's possible to use Bullet in tests (see more [here](https://evilmartians.com/chronicles/fighting-the-hydra-of-n-plus-one-queries)), but it's not a _silver bullet_: there can be both false positives and true negatives.

This gem was born after I've found myself not able to verify with a test yet another N+1 problem.

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add this line to your application's Gemfile:

```ruby
group :test do
  gem "n_plus_one_control"
end
```

And then execute:

    $ bundle

## Usage

### RSpec

First, add NPlusOneControl to your `spec_helper.rb`:

```ruby
# spec_helper.rb
require "n_plus_one_control/rspec"
```

Then:

```ruby
# Wrap example into a context with :n_plus_one tag
context "N+1", :n_plus_one do
  # Define `populate` callbacks which is responsible for data
  # generation (and whatever else).
  #
  # It accepts one argument – the scale factor (read below)
  populate { |n| create_list(:post, n) }

  specify do
    expect { get :index }.to perform_constant_number_of_queries
  end
end
```

**NOTE:** do not use memoized values within the expectation block!

```ruby
# BAD – won't work!

subject { get :index }

specify do
  expect { subject }.to perform_constant_number_of_queries
end
```

Availables modifiers:

```ruby
# You can specify the RegExp to filter queries.
# By default, it only considers SELECT queries.
expect { get :index }.to perform_constant_number_of_queries.matching(/INSERT/)

# You can also provide custom scale factors
expect { get :index }.to perform_constant_number_of_queries.with_scale_factors(10, 100)
```

#### Using scale factor in spec

Let's suppose your action accepts parameter, which can make impact on the number of returned records:

```ruby
get :index, params: {per_page: 10}
```

Then it is enough to just change `per_page` parameter between executions and do not recreate records in DB. For this purpose, you can use `current_scale` method in your example:

```ruby
context "N+1", :n_plus_one do
  before { create_list :post, 3 }

  specify do
    expect { get :index, params: {per_page: current_scale} }.to perform_constant_number_of_queries
  end
end
```

#### Other available matchers

`perform_linear_number_of_queries(slope: 1)` allows you to test that a query generates linear number of queries with the given slope.  

```ruby
context "when has linear query", :n_plus_one do
  populate { |n| create_list(:post, n) }

  specify do
    expect { Post.find_each { |p| p.user.name } }
      .to perform_linear_number_of_queries(slope: 1)
  end
end
```

### Minitest

First, add NPlusOneControl to your `test_helper.rb`:

```ruby
# test_helper.rb
require "n_plus_one_control/minitest"
```

Then use `assert_perform_constant_number_of_queries` assertion method:

```ruby
def test_no_n_plus_one_error
  populate = ->(n) { create_list(:post, n) }

  assert_perform_constant_number_of_queries(populate: populate) do
    get :index
  end
end
```

You can also specify custom scale factors or filter patterns:

```ruby
assert_perform_constant_number_of_queries(
  populate: populate,
  scale_factors: [2, 5, 10]
) do
  get :index
end

assert_perform_constant_number_of_queries(
  populate: populate,
  matching: /INSERT/
) do
  do_some_havey_stuff
end
```

It's possible to specify a filter via `NPLUSONE_FILTER` env var, e.g.:

```ruby
NPLUSONE_FILTER = users bundle exec rake test
```

You can also specify `populate` as a test class instance method:

```ruby
def populate(n)
  create_list(:post, n)
end

def test_no_n_plus_one_error
  assert_perform_constant_number_of_queries do
    get :index
  end
end

```

As in RSpec, you can use `current_scale` factor instead of `populate` block:

```ruby
def test_no_n_plus_one_error
  assert_perform_constant_number_of_queries do
    get :index, params: {per_page: current_scale}
  end
end
```

### With caching

If you use caching you can face the problem when first request performs more DB queries than others. The solution is:

```ruby
# RSpec

context "N + 1", :n_plus_one do
  populate { |n| create_list :post, n }

  warmup { get :index } # cache something must be cached

  specify do
    expect { get :index }.to perform_constant_number_of_queries
  end
end

# Minitest

def populate(n)
  create_list(:post, n)
end

def warmup
  get :index
end

def test_no_n_plus_one_error
  assert_perform_constant_number_of_queries do
    get :index
  end
end

# or with params

def test_no_n_plus_one
  populate = ->(n) { create_list(:post, n) }
  warmup = -> { get :index }

  assert_perform_constant_number_of_queries population: populate, warmup: warmup do
    get :index
  end
end
```

If your `warmup` and testing procs are identical, you can use:

```ruby
expext { get :index }.to perform_constant_number_of_queries.with_warming_up # RSpec only
```

### Configuration

There are some global configuration parameters (and their corresponding defaults):

```ruby
# Default scale factors to use.
# We use the smallest possible but representative scale factors by default.
NPlusOneControl.default_scale_factors = [2, 3]

# Print performed queries if true in the case of failure
# You can activate verbosity through env variable NPLUSONE_VERBOSE=1
NPlusOneControl.verbose = false

# Print table hits difference, for example:
#
#   Unmatched query numbers by tables:
#     users (SELECT): 2 != 3
#     events (INSERT): 1 != 2
#
self.show_table_stats = true

# Ignore matching queries
NPlusOneControl.ignore = /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/

# ActiveSupport notifications event to track queries.
# We track ActiveRecord event by default,
# but can also track rom-rb events ('sql.rom') as well.
NPlusOneControl.event = "sql.active_record"

# configure transactional behavour for populate method
# in case of use multiple database connections
NPlusOneControl::Executor.tap do |executor|
  connections = ActiveRecord::Base.connection_handler.connection_pool_list.map(&:connection)

  executor.transaction_begin = -> do
    connections.each { |connection| connection.begin_transaction(joinable: false) }
  end
  executor.transaction_rollback = -> do
    connections.each(&:rollback_transaction)
  end
end

# Provide a backtrace cleaner callable object used to filter SQL caller location to display in the verbose mode
# Set it to nil to disable tracing.
#
# In Rails apps, we use Rails.backtrace_cleaner by default.
NPlusOneControl.backtrace_cleaner = ->(locations_array) { do_some_filtering(locations_array) }

# You can also specify the number of backtrace lines to show.
# MOTE: It could be specified via NPLUSONE_BACKTRACE env var
NPlusOneControl.backtrace_length = 1

# Sometime queries could be too large to provide any meaningful insight.
# You can configure an output length limit for quries in verbose mode by setting the follwing option
# NOTE: It could be specified via NPLUSONE_TRUNCATE env var
NPlusOneControl.truncate_query_size = 100
```

## How does it work?

Take a look at our [Executor](https://github.com/palkan/n_plus_one_control/blob/master/lib/n_plus_one_control/executor.rb) to figure out what's under the hood.

## What's next?

- More matchers.

It may be useful to provide more matchers/assertions, for example:

```ruby

# Actually, that means that it is N+1))
assert_linear_number_of_queries { some_code }

# But we can tune it with `coef` and handle such cases as selecting in batches
assert_linear_number_of_queries(coef: 0.1) do
  Post.find_in_batches { some_code }
end

# probably, also make sense to add another curve types
assert_logarithmic_number_of_queries { some_code }
```

- Support custom non-SQL events.

N+1 problem is not a database specific: we can have N+1 Redis calls, N+1 HTTP external requests, etc.
We can make `n_plus_one_control` customizable to support these scenarios (technically, we need to make it possible to handle different payload in the event subscriber).

If you want to discuss or implement any of these, feel free to open an [issue](https://github.com/palkan/n_plus_one_control/issues) or propose a [pull request](https://github.com/palkan/n_plus_one_control/pulls).

## Development

```sh
# install deps
bundle install

# run tests
bundle exec rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/n_plus_one_control.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
