# frozen_string_literal: true

require "n_plus_one_control/collectors/db"

module NPlusOneControl
  # Runs code for every scale factor
  # and returns collected queries.
  class Executor
    class << self
      attr_accessor :transaction_begin
      attr_accessor :transaction_rollback
    end

    attr_reader :current_scale

    self.transaction_begin = -> do
      ActiveRecord::Base.connection.begin_transaction(joinable: false)
    end

    self.transaction_rollback = -> do
      ActiveRecord::Base.connection.rollback_transaction
    end

    def initialize(population: nil, scale_factors: nil, matching: nil)
      @population = population
      @scale_factors = scale_factors
      @matching = matching
    end

    # rubocop:disable Metrics/MethodLength
    def call(collectors: :db)
      raise ArgumentError, "Block is required!" unless block_given?

      results = []
      active_collectors = CollectorsRegistry.slice(*Array(collectors)).transform_values { |c| c.new(matching) }

      (scale_factors || NPlusOneControl.default_scale_factors).each do |scale|
        @current_scale = scale
        with_transaction do
          population&.call(scale)
          active_collectors.values.each(&:subscribe)
          yield
          results << [scale, active_collectors.transform_values(&:queries)]
          active_collectors.values.each(&:reset)
        end
      end
      results
    end
    # rubocop:enable Metrics/MethodLength

    private

    def with_transaction
      transaction_begin.call
      yield
    ensure
      transaction_rollback.call
    end

    def transaction_begin
      self.class.transaction_begin
    end

    def transaction_rollback
      self.class.transaction_rollback
    end

    attr_reader :population, :scale_factors, :matching
  end
end
