::RSpec.configure do |config|
  config.before(:each, :n_plus_one) do
    ::Isolator.incr_thresholds!
  end

  config.after(:each, :n_plus_one) do
    ::Isolator.decr_thresholds!
  end
end
