# frozen_string_literal: true

require "n_plus_one_control/version"
require "n_plus_one_control/executor"

# RSpec and Minitest matchers to prevent N+1 queries problem.
module NPlusOneControl
  class << self
    attr_accessor :default_scale_factors, :verbose, :ignore, :event
  end

  # Scale factors to use.
  # Use the smallest possible but representative scale factors by default.
  self.default_scale_factors = [2, 3]

  # Print perfromed queries if true
  self.verbose = false

  # Ignore matching queries
  self.ignore = /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/

  # ActiveSupport notifications event to track queries.
  # We track ActiveRecord event by default,
  # but can also track rom-rb events ('sql.rom') as well.
  self.event = 'sql.active_record'
end

require "n_plus_one_control/rspec" if defined?(RSpec)
