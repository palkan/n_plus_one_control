# frozen_string_literal: true

RSpec.shared_context "n_plus_one_control" do
  # Helper to access populate block from within example/matcher
  let(:n_plus_one_populate) do |ex|
    return if ex.example_group.populate.nil?

    ->(n) { ex.instance_exec(n, &ex.example_group.populate) }
  end

  let(:n_plus_one_warmup) do |ex|
    return if ex.example_group.warmup.nil?

    -> { ex.instance_exec(&ex.example_group.warmup) }
  end
end

RSpec.configure do |config|
  config.include_context "n_plus_one_control", n_plus_one: true
end
