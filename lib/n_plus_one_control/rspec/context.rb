# frozen_string_literal: true

::RSpec.shared_context "n_plus_one_control", n_plus_one: true do
  # Helper to access populate block from within example/matcher
  let(:n_plus_one_populate) do |ex|
    if ex.example_group.populate.nil?
      raise(
        <<-MSG
          Populate block is missing!

          Please provide populate callback, e.g.:

            populate { |n| n.times { create_some_stuff } }
        MSG
      )
    end
    ->(n) { ex.instance_exec(n, &ex.example_group.populate) }
  end
end
