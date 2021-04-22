# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::RSpec do
  describe "perform_linear_number_of_queries" do
    context "when constant queries", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect do
          expect { Post.preload(:user).find_each { |p| p.user.name } }
            .to perform_linear_number_of_queries(slope: 1)
        end.not_to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context "when has linear query", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_linear_number_of_queries(slope: 1)
      end
    end

    context "when has linear query larger than expected slope", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect do
          expect { Post.find_each { |p| "#{p.user.name} #{p.category.name}" } }
            .to perform_linear_number_of_queries(slope: 1)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context "when context is missing" do
      specify do
        expect do
          expect { subject }.to perform_linear_number_of_queries
        end.to raise_error(/missing tag/i)
      end
    end

    context "when negated" do
      specify do
        expect do
          expect { subject }.not_to perform_linear_number_of_queries
        end.to raise_error(/support negation/i)
      end
    end

    context "with scale_factors", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_linear_number_of_queries(slope: 1).with_scale_factors(2, 3)
      end
    end

    context "with matching", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_linear_number_of_queries.matching(/users/)
      end

      context "with matching is provided globally", :n_plus_one do
        around(:each) do |ex|
          old_matching = NPlusOneControl.default_matching
          NPlusOneControl.default_matching = "users"
          ex.run
          NPlusOneControl.default_matching = old_matching
        end

        populate { |n| create_list(:post, n) }

        specify do
          expect { Post.find_each { |p| p.user.name } }
            .to perform_linear_number_of_queries
        end
      end
    end

    context "with warming up", :n_plus_one do
      let(:cache) { double "cache" }

      before do
        allow(cache).to receive(:setup).and_return(:result)
      end

      populate { |n| create_list(:post, n) }

      warmup { cache.setup }

      it "runs warmup before calling Executor" do
        expect(cache).to receive(:setup)
        expect { Post.find_each(&:id) }.to perform_linear_number_of_queries
      end
    end

    context "with_warming_up", :n_plus_one do
      populate { |n| create_list(:post, n) }

      it "runs actual one more time" do
        expect(Post).to receive(:all).exactly(NPlusOneControl.default_scale_factors.size + 1).times
        expect { Post.all }.to perform_linear_number_of_queries.with_warming_up
      end
    end
  end
end
