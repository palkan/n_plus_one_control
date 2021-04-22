# frozen_string_literal: true

require "n_plus_one_control/collectors_registry"

module NPlusOneControl
  module Collectors
    class DB
      class << self
        attr_accessor :key

        def failure_message(type, queries)
          msg = ["#{::NPlusOneControl::FAILURE_MESSAGES[type]} to database, but got:\n"]
          queries.each do |(scale, data)|
            msg << "  #{data[:db].size} for N=#{scale}\n"
          end

          msg.concat(table_usage_stats(queries.map(&:last))) if NPlusOneControl.show_table_stats

          if NPlusOneControl.verbose
            queries.each do |(scale, data)|
              msg << "Queries for N=#{scale}\n"
              msg << data[:db].map { |sql| "  #{truncate_query(sql)}\n" }.join.to_s
            end
          end

          msg.join
        end

        def table_usage_stats(runs) # rubocop:disable Metrics/MethodLength
          msg = ["Unmatched query numbers by tables:\n"]

          before, after = runs.map do |queries|
            queries[:db].group_by do |query|
              matches = query.match(EXTRACT_TABLE_RXP)
              next unless matches

              "  #{matches[2]} (#{QUERY_PART_TO_TYPE[matches[1].downcase]})"
            end.transform_values(&:count)
          end

          before.keys.each do |k|
            next if before[k] == after[k]

            msg << "#{k}: #{before[k]} != #{after[k]}\n"
          end

          msg
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

      def initialize(pattern)
        @pattern = pattern
        @queries = []
      end

      def subscribe
        @subscriber = ActiveSupport::Notifications.subscribe(NPlusOneControl.event, method(:callback))
      end

      def reset
        unsubscribe
        @queries = []
      end

      def callback(_name, _start, _finish, _message_id, values) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/LineLength
        return if %w[CACHE SCHEMA].include? values[:name]

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

      def unsubscribe
        ActiveSupport::Notifications.unsubscribe(@subscriber)
      end
    end
  end
end

NPlusOneControl::CollectorsRegistry.register(NPlusOneControl::Collectors::DB)
