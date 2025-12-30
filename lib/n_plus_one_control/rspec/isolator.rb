::RSpec.configure do |config|
  config.before(:begin, :n_plus_one) do
    ::Isolator.incr_thresholds!
  end

  config.after(:rollback, :n_plus_one) do
    ::Isolator.decr_thresholds!
  end
end
