# frozen_string_literal: true

require "n_plus_one_control"

module NPlusOneControl
  # Minitest assertions
  module MinitestHelper
    def assert_perform_constant_number_of_queries(
      populate: nil,
      matching: nil,
      scale_factors: nil
    )

      raise ArgumentError, "Block is required" unless block_given?

      queries = NPlusOneControl::Executor.call(
        population: populate || method(:populate),
        matching: matching || /^SELECT/i,
        scale_factors: scale_factors || NPlusOneControl.default_scale_factors
      ) { yield }

      counts = queries.map(&:last).map(&:size)

      assert counts.max == counts.min, NPlusOneControl.failure_message(queries)
    end
  end
end

Minitest::Test.include NPlusOneControl::MinitestHelper
