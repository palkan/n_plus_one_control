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

      def callback(_name, _start, _finish, _message_id, values) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/LineLength
        return if %w[CACHE SCHEMA].include? values[:name]
        return if values[:sql].match?(NPlusOneControl.ignore)
        return if values[:cached] && NPlusOneControl.ignore_cached_queries

        return unless @pattern.nil? || (values[:sql] =~ @pattern)

        query = values[:sql]

        if NPlusOneControl.backtrace_cleaner && NPlusOneControl.verbose
          source = extract_query_source_location(caller)

          query = "#{query}\n    ↳ #{source.join("\n")}" unless source.empty?
        end

        @queries << query
      end

      private

      def extract_query_source_location(locations)
        NPlusOneControl.backtrace_cleaner.call(locations.lazy)
          .take(NPlusOneControl.backtrace_length).to_a
      end
    end

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
    def call
      raise ArgumentError, "Block is required!" unless block_given?

      results = []
      collector = Collector.new(matching)

      (scale_factors || NPlusOneControl.default_scale_factors).each do |scale|
        @current_scale = scale
        with_transaction do
          population&.call(scale)
          results << [scale, collector.call { yield }]
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
