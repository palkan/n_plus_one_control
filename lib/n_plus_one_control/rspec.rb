# frozen_string_literal: true

gem "rspec-core", ">= 3.5"

require "n_plus_one_control"
require "n_plus_one_control/rspec/dsl"
require "n_plus_one_control/rspec/matchers/perform_constant_number_of_queries"
require "n_plus_one_control/rspec/matchers/perform_linear_number_of_queries"
require "n_plus_one_control/rspec/context"

module NPlusOneControl
  module RSpec # :nodoc:
  end
end

::RSpec.configure do |config|
  config.extend NPlusOneControl::RSpec::DSL::ClassMethods, n_plus_one: true
  config.include NPlusOneControl::RSpec::DSL, n_plus_one: true
end
