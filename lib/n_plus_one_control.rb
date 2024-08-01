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

  class << self
    attr_accessor :default_scale_factors, :verbose, :show_table_stats, :ignore, :event,
      :backtrace_cleaner, :backtrace_length, :truncate_query_size, :ignore_cached_queries

    attr_reader :default_matching

    FAILURE_MESSAGES = {
      constant_queries: "Expected to make the same number of queries",
      linear_queries: "Expected to make linear number of queries",
      number_of_queries: "Expected to make the specified number of queries"
    }

    def failure_message(type, queries) # rubocop:disable Metrics/MethodLength
      msg = ["#{FAILURE_MESSAGES[type]}, but got:\n"]
      queries.each do |(scale, data)|
        msg << "  #{data.size} for N=#{scale}\n"
      end

      msg.concat(table_usage_stats(queries.map(&:last))) if show_table_stats

      if verbose
        queries.each do |(scale, data)|
          msg << "Queries for N=#{scale}\n"
          msg << data.map { |sql| "  #{truncate_query(sql)}\n" }.join.to_s
        end
      end

      msg.join
    end

    def table_usage_stats(runs) # rubocop:disable Metrics/MethodLength
      msg = ["Unmatched query numbers by tables:\n"]

      before, after = runs.map do |queries|
        queries.group_by do |query|
          matches = query.match(EXTRACT_TABLE_RXP)
          next unless matches

          "  #{matches[2]} (#{QUERY_PART_TO_TYPE[matches[1].downcase]})"
        end.transform_values(&:count)
      end

      before.keys.each do |k|
        next if before[k] == after&.fetch(k, nil)

        after_value = after ? " != #{after[k]}" : ""
        msg << "#{k}: #{before[k]}#{after_value}\n"
      end

      msg
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

    private

    def truncate_query(sql)
      return sql unless truncate_query_size

      # Only truncate query, leave tracing (if any) as is
      parts = sql.split(/(\s+↳)/)

      parts[0] =
        if truncate_query_size < 4
          "..."
        else
          parts[0][0..(truncate_query_size - 4)] + "..."
        end

      parts.join
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

  # Ignore queries cached
  self.ignore_cached_queries = false

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
