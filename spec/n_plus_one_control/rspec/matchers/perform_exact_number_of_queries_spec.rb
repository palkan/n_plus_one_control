# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::RSpec do
  context "when number of queries match exactly", :n_plus_one do
    populate { |n| create_list(:post, n) }

    specify do
      expect { Post.take }
        .to perform_constant_number_of_queries.exactly(1)
    end
  end

  context "when number of queries do not match exactly", :n_plus_one do
    populate { |n| create_list(:post, n) }

    specify do
      expect do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_constant_number_of_queries.exactly(1)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  context "exact number has precedence over scale factor", :n_plus_one do
    specify do
      expected_params = {population: nil, matching: /INSERT/, scale_factors: [1]}
      executor = NPlusOneControl::Executor.new(**expected_params)
      expect(NPlusOneControl::Executor).to receive(:new).with(**expected_params).and_return(executor)
      expect { Post.take }.to perform_constant_number_of_queries.exactly(0).matching(/INSERT/).with_scale_factors(2, 3)
    end
  end
end
