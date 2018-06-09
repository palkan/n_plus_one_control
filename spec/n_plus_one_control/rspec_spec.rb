# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::RSpec do
  context "when no N+1", :n_plus_one do
    populate { |n| create_list(:post, n) }

    specify do
      expect { Post.preload(:user).find_each { |p| p.user.name } }
        .to perform_constant_number_of_queries
    end
  end

  context "when has N+1", :n_plus_one do
    populate { |n| create_list(:post, n) }

    specify do
      expect do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_constant_number_of_queries
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  context "when context is missing" do
    specify do
      expect do
        expect { subject }.to perform_constant_number_of_queries
      end.to raise_error(/missing tag/i)
    end
  end

  context "when populate is missing", :n_plus_one do
    specify do
      expect do
        expect { subject }.to perform_constant_number_of_queries
      end.to raise_error(/please provide populate/i)
    end
  end

  context "when negated" do
    specify do
      expect do
        expect { subject }.not_to perform_constant_number_of_queries
      end.to raise_error(/support negation/i)
    end
  end

  context "when verbose", :n_plus_one do
    populate { |n| create_list(:post, n) }

    around(:each) do |ex|
      NPlusOneControl.verbose = true
      ex.run
      NPlusOneControl.verbose = false
    end

    specify do
      expect do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_constant_number_of_queries
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /select .+ from/i)
    end
  end

  context "with scale_factors", :n_plus_one do
    populate { |n| create_list(:post, n) }

    specify do
      expect { Post.find_each { |p| p.user.name } }
        .to perform_constant_number_of_queries.with_scale_factors(1, 1)
    end
  end

  context "with matching", :n_plus_one do
    populate { |n| create_list(:post, n) }

    specify do
      expect { Post.find_each { |p| p.user.name } }
        .to perform_constant_number_of_queries.matching(/posts/)
    end
  end

  context 'with warming up', :n_plus_one do
    let(:cache) { double "cache" }

    before do
      allow(cache).to receive(:setup).and_return(:result)
      allow(NPlusOneControl::Executor).to receive(:call) { fail StandardError }
    end

    populate { |n| create_list(:post, n) }

    warmup { cache.setup }

    it "runs warmup before calling Executor" do
      expect(cache).to receive(:setup)
      expect do
        expect { Post.find_each(&:id) }.to perform_constant_number_of_queries
      end.to raise_error StandardError
    end
  end
end
