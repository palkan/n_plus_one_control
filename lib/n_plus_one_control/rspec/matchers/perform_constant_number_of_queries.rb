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

  match do |actual, *_args|
    raise ArgumentError, "Block is required" unless actual.is_a? Proc

    raise "Missing tag :n_plus_one" unless
      @matcher_execution_context.respond_to?(:n_plus_one_populate)

    populate = @matcher_execution_context.n_plus_one_populate
    warmup = @warmup ? actual : @matcher_execution_context.n_plus_one_warmup

    warmup.call if warmup.present?

    pattern = @pattern || NPlusOneControl.default_matching

    @matcher_execution_context.executor = NPlusOneControl::Executor.new(
      population: populate,
      matching: pattern,
      scale_factors: @factors
    )

    @queries = @matcher_execution_context.executor.call(&actual)

    counts = @queries.map { |q| q.last[:db] }.map(&:size)

    counts.max == counts.min
  end

  match_when_negated do |_actual|
    raise "This matcher doesn't support negation"
  end

  failure_message { |_actual| NPlusOneControl.failure_message(:constant_queries, @queries) }
end
# rubocop:enable  Metrics/BlockLength
