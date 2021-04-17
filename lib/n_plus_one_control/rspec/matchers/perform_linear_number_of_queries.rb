# frozen_string_literal: true

# rubocop:disable  Metrics/BlockLength
::RSpec::Matchers.define :perform_linear_number_of_queries do |slope: 1|
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
    collectors = @collectors || :db

    @matcher_execution_context.executor = NPlusOneControl::Executor.new(
      population: populate,
      matching: nil,
      scale_factors: @factors
    )

    @queries = @matcher_execution_context.executor.call(collectors: collectors, &actual)

    @queries.each_cons(2).all? do |pair|
      scales = pair.map(&:first)
      query_lists = pair.map(&:last)

      actual_slopes = query_lists[0].keys.map do |key|
        (query_lists[1][key].size - query_lists[0][key].size) / (scales[1] - scales[0])
      end

      actual_slopes.all? { |actual_slope| actual_slope <= slope }
    end
  end

  match_when_negated do |_actual|
    raise "This matcher doesn't support negation"
  end

  failure_message { |_actual| NPlusOneControl.failure_message(:linear_queries, @queries) }
end
# rubocop:enable  Metrics/BlockLength
