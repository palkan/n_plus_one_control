# frozen_string_literal: true

# rubocop:disable  Metrics/BlockLength
::RSpec::Matchers.define :perform_constant_number_of_queries do
  supports_block_expectations

  chain :with_scale_factors do |*factors|
    @factors = factors
  end

  chain :matching do |pattern|
    @pattern = pattern
  end

  chain :with_warming_up do
    @warmup = true
  end

  chain :to do |*collectors|
    @collectors = collectors
  end

  match(notify_expectation_failures: true) do |actual, *_args|
    raise ArgumentError, "Block is required" unless actual.is_a? Proc

    raise "Missing tag :n_plus_one" unless
      @matcher_execution_context.respond_to?(:n_plus_one_populate)

    populate = @matcher_execution_context.n_plus_one_populate
    warmup = @warmup ? actual : @matcher_execution_context.n_plus_one_warmup

    warmup.call if warmup.present?

    pattern = @pattern || NPlusOneControl.default_matching
    collectors = @collectors || :db

    @matcher_execution_context.executor = NPlusOneControl::Executor.new(
      population: populate,
      matching: pattern,
      scale_factors: @factors
    )

    @queries = @matcher_execution_context.executor.call(collectors: collectors, &actual)

    counts = @queries.map { |q| q.last.transform_values(&:size) }

    results = Array(collectors).map do |c|
      counts_by_collector = counts.map { |count| count[c] }
      [c, counts_by_collector.max == counts_by_collector.min]
    end.to_h

    results.values.all?
  end

  match_when_negated do |_actual|
    raise "This matcher doesn't support negation"
  end

  failure_message { |_actual| NPlusOneControl.failure_message(:constant_queries, @queries) }
end
# rubocop:enable  Metrics/BlockLength
