# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'n_plus_one_control/version'

Gem::Specification.new do |spec|
  spec.name          = "n_plus_one_control"
  spec.version       = NPlusOneControl::VERSION
  spec.authors       = ["palkan"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "RSpec and Minitest matchers to prevent N+1 queries problem"
  spec.description   = %{
    RSpec and Minitest matchers to prevent N+1 queries problem.

    Evaluates code under consideration several times with different scale factors
    to make sure that the number of DB queries behaves as expected (i.e. O(1) instead of O(N)).

    Example:

      ```ruby
      context "N+1", :n_plus_one do
        populate { |n| create_list(:post, n) }

        specify do
          expect { get :index }.to perform_constant_number_of_queries
        end
      end
      ```
  }
  spec.homepage      = "http://github.com/palkan/n_plus_one_control"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "minitest", "~> 5.9"
  spec.add_development_dependency "factory_girl", "~> 4.8.0"
  spec.add_development_dependency "rubocop", "~> 0.49"
  spec.add_development_dependency "activerecord", "~> 5.1"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pry-byebug"
end
