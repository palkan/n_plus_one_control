# frozen_string_literal: true

require "n_plus_one_control/collectors_registry"
require "n_plus_one_control/collectors/base"

module NPlusOneControl
  module Collectors
    class DB < Base
      class << self
        # Used to convert a query part extracted by the regexp above to the corresponding
        # human-friendly type
        QUERY_PART_TO_TYPE = {
          "insert into" => "INSERT",
          "update" => "UPDATE",
          "delete from" => "DELETE",
          "from" => "SELECT"
        }.freeze

        # This method enriches default error message with table usage stats
        def failure_message(_, queries)
          msg = super

          msg << table_usage_stats(queries.map(&:last)) if NPlusOneControl.show_table_stats

          if NPlusOneControl.verbose
            queries.each do |(scale, data)|
              msg << "Queries for N=#{scale}\n"
              msg << data[key].map { |sql| "  #{truncate_query(sql)}\n" }.join.to_s
            end
          end

          msg
        end

        private

        def table_usage_stats(runs) # rubocop:disable Metrics/MethodLength
          msg = ["Unmatched query numbers by tables:\n"]

          before, after = runs.map do |queries|
            queries[key].group_by do |query|
              matches = query.match(EXTRACT_TABLE_RXP)
              next unless matches

              "  #{matches[2]} (#{QUERY_PART_TO_TYPE[matches[1].downcase]})"
            end.transform_values(&:count)
          end

          before.keys.each do |k|
            next if before[k] == after[k]

            msg << "#{k}: #{before[k]} != #{after[k]}\n"
          end

          msg.join
        end

        def truncate_query(sql)
          return sql unless NPlusOneControl.truncate_query_size

          # Only truncate query, leave tracing (if any) as is
          parts = sql.split(/(\s+↳)/)

          parts[0] =
            if NPlusOneControl.truncate_query_size < 4
              "..."
            else
              parts[0][0..(NPlusOneControl.truncate_query_size - 4)] + "..."
            end

          parts.join
        end
      end

      attr_reader :queries

      self.key = :db
      self.name = "database"
      self.event = -> { NPlusOneControl.event }

      def callback(_name, _start, _finish, _message_id, values) # rubocop:disable Metrics/CyclomaticComplexity,Layout/LineLength
        return if %w[CACHE SCHEMA].include? values[:name]
        return if values[:sql].match?(NPlusOneControl.ignore)

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
  end
end

NPlusOneControl::CollectorsRegistry.register(NPlusOneControl::Collectors::DB)
