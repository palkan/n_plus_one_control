# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "n_plus_one_control/rspec"
require "benchmark"
require "active_record"
require "factory_girl"
require "pry-byebug"

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.order = :random
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  config.after(:each) do
    ActiveRecord::Base.connection.rollback_transaction
  end
end
