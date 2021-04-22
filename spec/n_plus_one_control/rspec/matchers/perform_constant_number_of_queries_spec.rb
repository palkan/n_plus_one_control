# frozen_string_literal: true

require "spec_helper"

describe NPlusOneControl::RSpec do
  describe "perform_constant_number_of_queries" do
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
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /select .+ from.*↳ .*_spec.rb:\d+/im)
      end

      context "when truncate size is specified" do
        populate { |n| create_list(:post, n) }

        around(:each) do |ex|
          NPlusOneControl.truncate_query_size = 6
          ex.run
          NPlusOneControl.truncate_query_size = nil
        end

        specify do
          expect do
            expect { Post.find_each { |p| p.user.name } }
              .to perform_constant_number_of_queries
          end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /sel\.\.\./i)
        end
      end

      context "when backtrace length is specified" do
        populate { |n| create_list(:post, n) }

        around(:each) do |ex|
          NPlusOneControl.backtrace_length = 2
          ex.run
          NPlusOneControl.backtrace_length = 1
        end

        specify do
          expect do
            expect { Post.find_each { |p| p.user.name } }
              .to perform_constant_number_of_queries
          end.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /select .+ from.*↳.*_spec.rb:\d+.*\n.*_spec.rb:\d+/im
          )
        end
      end
    end

    context "with table stats", :n_plus_one do
      populate { |n| create_list(:post, n) }

      around(:each) do |ex|
        NPlusOneControl.show_table_stats = true
        ex.run
        NPlusOneControl.show_table_stats = false
      end

      specify do
        expect do
          expect { Post.find_each { |p| p.user.name } }
            .to perform_constant_number_of_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /users \(SELECT\): 2 != 3/i)
      end
    end

    context "with scale_factors", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect { Post.preload(:user).find_each { |p| p.user.name } }
          .to perform_constant_number_of_queries.with_scale_factors(1, 2)
      end
    end

    context "with matching", :n_plus_one do
      populate { |n| create_list(:post, n) }

      specify do
        expect { Post.find_each { |p| p.user.name } }
          .to perform_constant_number_of_queries.matching(/posts/)
      end

      context "with matching is provided globally", :n_plus_one do
        around(:each) do |ex|
          old_matching = NPlusOneControl.default_matching
          NPlusOneControl.default_matching = "posts"
          ex.run
          NPlusOneControl.default_matching = old_matching
        end

        populate { |n| create_list(:post, n) }

        specify do
          expect { Post.find_each { |p| p.user.name } }
            .to perform_constant_number_of_queries
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
        expect { Post.find_each(&:id) }.to perform_constant_number_of_queries
      end
    end

    context "with_warming_up", :n_plus_one do
      populate { |n| create_list(:post, n) }

      it "runs actual one more time" do
        expect(Post).to receive(:all).exactly(NPlusOneControl.default_scale_factors.size + 1).times
        expect { Post.all }.to perform_constant_number_of_queries.with_warming_up
      end
    end

    context "with usage of current_scale instead of populate", :n_plus_one do
      it "can use current current_scale", :aggregate_failures do
        NPlusOneControl.default_scale_factors.each do |scale_factor|
          expect(Post).to receive(:limit).with(scale_factor).once
        end

        expect { Post.limit(current_scale) }.to perform_constant_number_of_queries
      end
    end
  end
end
