# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

begin
  require "pry-byebug"
rescue LoadError
end

$LOAD_PATH << File.expand_path("../lib", __dir__)
Thread.abort_on_exception = true

require "n_plus_one_control/minitest"
require "benchmark"
require "active_record"
require "factory_bot"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

Dir["#{File.dirname(__FILE__)}/../spec/support/**/*.rb"].sort.each { |f| require f }

module TransactionalTests
  def setup
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    super
  end

  def teardown
    super
    ActiveRecord::Base.connection.rollback_transaction
  end
end

Minitest::Test.prepend TransactionalTests
Minitest::Test.include FactoryBot::Syntax::Methods
