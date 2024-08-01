# Change log

## master

- add ability to ignore queries cached by the ORM with the new option `ignore_cached_queries` ([@gagalago][])

## 0.7.1 (2023-02-17)

- Recognize private `#populate` and `#warmup` methods in Minitest classes. ([@palkan][])

## 0.7.0 (2023-02-17)

- Added ability to specify the exact number of expected queries when using constant matchers. ([@akostadinov][], [@palkan][])

For RSpec, you can add the `.exactly` modifier:

```ruby
expect { get :index }.to perform_constant_number_of_queries.exactly(1)
```

For Minitest, you can provide the expected number of queries as the first argument:

```ruby
assert_perform_constant_number_of_queries(0, **options) do
  get :index
end
```

- **Require Ruby 2.7+**.

## 0.6.2 (2021-10-26)

- Fix .ignore setting (.ignore setting was ignored by the Collector ;-))
- Fix rspec matchers to allow expectations inside execution block

## 0.6.1 (2021-03-05)

- Ruby 3.0 compatibility. ([@palkan][])

## 0.6.0 (2020-11-27)

- Fix table stats summary when queries use backticks to surround table names ([@andrewhampton][])
- Add support to test for linear query. ([@caalberts][])

## 0.5.0 (2020-09-07)

- **Ruby 2.5+ is required**. ([@palkan][])

- Add support for multiple backtrace lines in verbose output. ([@palkan][])

Could be specified via `NPLUSONE_BACKTRACE` env var.

- Add `NPLUSONE_TRUNCATE` env var to truncate queries in verbose mode. ([@palkan][])

- Support passing default filter via `NPLUSONE_FILTER` env var. ([@palkan][])

- Add location tracing to SQLs in verbose mode. ([@palkan][])

## 0.4.1 (2020-09-04)

- Enhance failure message by showing differences in table hits. ([@palkan][])

## 0.4.0 (2020-07-20)

- Make scale factor available in tests via `#current_scale` method. ([@Earendil95][])

- Start keeping a changelog. ([@palkan][])

[@Earendil95]: https://github.com/Earendil95
[@palkan]: https://github.com/palkan
[@caalberts]: https://github.com/caalberts
[@andrewhampton]: https://github.com/andrewhampton
[@akostadinov]: https://github.com/akostadinov
