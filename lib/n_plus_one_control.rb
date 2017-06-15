# frozen_string_literal: true

require "n_plus_one_control/version"
require "n_plus_one_control/executor"

# RSpec and Minitest matchers to prevent N+1 queries problem.
module NPlusOneControl
  class << self
    attr_accessor :default_scale_factors, :verbose, :ignore, :event

    def failure_message(queries)
      msg = ["Expected to make the same number of queries, but got:\n"]
      queries.each do |(scale, data)|
        msg << "  #{data.size} for N=#{scale}\n"
        msg << data.map { |sql| "    #{sql}\n" }.join.to_s if verbose
      end
      msg.join
    end
  end

  # Scale factors to use.
  # Use the smallest possible but representative scale factors by default.
  self.default_scale_factors = [2, 3]

  # Print performed queries if true
  self.verbose = ENV['NPLUSONE_VERBOSE'] == '1'

  # Ignore matching queries
  self.ignore = /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/

  # ActiveSupport notifications event to track queries.
  # We track ActiveRecord event by default,
  # but can also track rom-rb events ('sql.rom') as well.
  self.event = 'sql.active_record'
end
