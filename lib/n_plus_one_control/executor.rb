# frozen_string_literal: true

module NPlusOneControl
  # Runs code for every scale factor
  # and returns collected queries.
  class Executor
    # Subscribes to ActiveSupport notifications and collect matching queries.
    class Collector
      def initialize(pattern)
        @pattern = pattern
      end

      def call
        @queries = []
        ActiveSupport::Notifications
          .subscribed(method(:callback), NPlusOneControl.event) do
          yield
        end
        @queries
      end

      def callback(_name, _start, _finish, _message_id, values)
        return if %w[CACHE SCHEMA].include? values[:name]

        @queries << values[:sql] if @pattern.nil? || (values[:sql] =~ @pattern)
      end
    end

    class << self
      attr_accessor :transaction_begin
      attr_accessor :transaction_rollback
    end

    attr_reader :scale

    self.transaction_begin = -> do
      ActiveRecord::Base.connection.begin_transaction(joinable: false)
    end

    self.transaction_rollback = -> do
      ActiveRecord::Base.connection.rollback_transaction
    end

    def initialize(population: nil, scale_factors: nil, matching: nil)
      @population, @scale_factors, @matching = population, scale_factors, matching
    end

    def call
      raise ArgumentError, "Block is required!" unless block_given?

      results = []
      collector = Collector.new(matching)

      (scale_factors || NPlusOneControl.default_scale_factors).each do |scale|
        @scale = scale
        with_transaction do
          population&.call(scale)
          results << [scale, collector.call { yield }]
        end
      end
      results
    end

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
