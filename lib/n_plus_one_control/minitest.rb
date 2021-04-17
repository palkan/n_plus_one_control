# frozen_string_literal: true

require "n_plus_one_control"

module NPlusOneControl
  # Minitest assertions
  module MinitestHelper
    def assert_perform_constant_number_of_queries(
      populate: nil,
      matching: nil,
      scale_factors: nil,
      warmup: nil,
      collectors: :db
    )

      raise ArgumentError, "Block is required" unless block_given?

      warming_up warmup

      @executor = NPlusOneControl::Executor.new(
        population: populate || population_method,
        matching: matching || NPlusOneControl.default_matching,
        scale_factors: scale_factors || NPlusOneControl.default_scale_factors
      )

      queries = @executor.call(collectors: collectors) { yield }

      counts = queries.map { |q| q.last.transform_values(&:size) }

      results = Array(collectors).map do |c|
        counts_by_collector = counts.map { |count| count[c] }
        [c, counts_by_collector.max == counts_by_collector.min]
      end.to_h

      assert results.values.all?, NPlusOneControl.failure_message(:constant_queries, queries)
    end

    def assert_perform_linear_number_of_queries(
      slope: 1,
      populate: nil,
      matching: nil,
      scale_factors: nil,
      warmup: nil,
      collectors: :db
    )

      raise ArgumentError, "Block is required" unless block_given?

      warming_up warmup

      @executor = NPlusOneControl::Executor.new(
        population: populate || population_method,
        matching: matching || NPlusOneControl.default_matching,
        scale_factors: scale_factors || NPlusOneControl.default_scale_factors
      )

      queries = @executor.call(collectors: collectors) { yield }

      assert linear?(queries, slope: slope), NPlusOneControl.failure_message(:linear_queries, queries)
    end

    def current_scale
      @executor&.current_scale
    end

    private

    def warming_up(warmup)
      (warmup || methods.include?(:warmup) ? method(:warmup) : nil)&.call
    end

    def population_method
      methods.include?(:populate) ? method(:populate) : nil
    end

    def linear?(queries, slope:)
      queries.each_cons(2).all? do |pair|
        scales = pair.map(&:first)
        query_lists = pair.map(&:last)

        actual_slopes = query_lists[0].keys.map do |key|
          (query_lists[1][key].size - query_lists[0][key].size) / (scales[1] - scales[0])
        end

        actual_slopes.all? { |actual_slope| actual_slope <= slope }
      end
    end
  end
end

Minitest::Test.include NPlusOneControl::MinitestHelper
