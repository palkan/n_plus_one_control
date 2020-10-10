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
  end
end
