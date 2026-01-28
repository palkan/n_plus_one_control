# frozen_string_literal: true

require_relative "lib/n_plus_one_control/version"

Gem::Specification.new do |spec|
  spec.name = "n_plus_one_control"
  spec.version = NPlusOneControl::VERSION
  spec.authors = ["palkan"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "RSpec and Minitest matchers to prevent N+1 queries problem"
  spec.required_ruby_version = ">= 3.1.0"
  spec.description = %{
    RSpec and Minitest matchers to prevent N+1 queries problem.

    Evaluates code under consideration several times with different scale factors
    to make sure that the number of DB queries behaves as expected (i.e. O(1) instead of O(N)).
  }
  spec.homepage = "https://github.com/palkan/n_plus_one_control"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "documentation_uri" => spec.homepage,
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage
  }

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "benchmark"
  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "minitest", "~> 5.9"
  spec.add_development_dependency "factory_bot", "~> 6.0"
end
