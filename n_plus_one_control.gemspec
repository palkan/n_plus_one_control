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
  spec.required_ruby_version = '>= 2.0.0'
  spec.description   = %{
    RSpec and Minitest matchers to prevent N+1 queries problem.

    Evaluates code under consideration several times with different scale factors
    to make sure that the number of DB queries behaves as expected (i.e. O(1) instead of O(N)).
  }
  spec.homepage      = "http://github.com/palkan/n_plus_one_control"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency "rspec", "~> 3.5"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.9"
  spec.add_development_dependency "factory_girl", "~> 4.8.0"
  spec.add_development_dependency "rubocop", "~> 0.61.0"
  spec.add_development_dependency "activerecord", "~> 5.1"
  spec.add_development_dependency "sqlite3", "~> 1.3.6"
  spec.add_development_dependency "pry-byebug"
end
