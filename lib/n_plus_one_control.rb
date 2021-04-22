# frozen_string_literal: true

require "n_plus_one_control/version"
require "n_plus_one_control/executor"

# RSpec and Minitest matchers to prevent N+1 queries problem.
module NPlusOneControl
  # Used to extract a table name from a query
  EXTRACT_TABLE_RXP = /(insert into|update|delete from|from) ['"`](\S+)['"`]/i.freeze

  # Used to convert a query part extracted by the regexp above to the corresponding
  # human-friendly type
  QUERY_PART_TO_TYPE = {
    "insert into" => "INSERT",
    "update" => "UPDATE",
    "delete from" => "DELETE",
    "from" => "SELECT"
  }.freeze

  FAILURE_MESSAGES = {
    constant_queries: "Expected to make the same number of queries",
    linear_queries: "Expected to make linear number of queries"
  }

  class << self
    attr_accessor :default_scale_factors, :verbose, :show_table_stats, :ignore, :event,
      :backtrace_cleaner, :backtrace_length, :truncate_query_size

    attr_reader :default_matching

    def failure_message(type, queries) # rubocop:disable Metrics/MethodLength
      queries.first.last.keys
        .map { |collector_key| NPlusOneControl::CollectorsRegistry.get(collector_key).failure_message(type, queries) }
        .join("\n\n")
    end

    def default_matching=(val)
      unless val
        @default_matching = nil
        return
      end

      @default_matching =
        if val.is_a?(Regexp)
          val
        else
          Regexp.new(val, Regexp::MULTILINE | Regexp::IGNORECASE)
        end
    end
  end

  # Scale factors to use.
  # Use the smallest possible but representative scale factors by default.
  self.default_scale_factors = [2, 3]

  # Print performed queries if true
  self.verbose = ENV["NPLUSONE_VERBOSE"] == "1"

  # Print table hits difference
  self.show_table_stats = true

  # Ignore matching queries
  self.ignore = /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/

  # ActiveSupport notifications event to track queries.
  # We track ActiveRecord event by default,
  # but can also track rom-rb events ('sql.rom') as well.
  self.event = "sql.active_record"

  # Default query filtering applied if none provided explicitly
  self.default_matching = ENV["NPLUSONE_FILTER"] || /^SELECT/i

  # Truncate queries in verbose mode to fit the length
  self.truncate_query_size = ENV["NPLUSONE_TRUNCATE"]&.to_i

  # Define the number of backtrace lines to show
  self.backtrace_length = ENV.fetch("NPLUSONE_BACKTRACE", 1).to_i
end

require "n_plus_one_control/railtie" if defined?(Rails::Railtie)
