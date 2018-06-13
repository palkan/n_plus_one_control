# frozen_string_literal: true

module NPlusOneControl
  module RSpec
    # Extends RSpec ExampleGroup with populate & warmup methods
    module DSL
      # Setup warmup block, wich will run before matching
      # for example, if using cache, then later queries
      # will perform less DB queries than first
      def warmup
        return @warmup unless block_given?

        @warmup = Proc.new
      end

      # Setup populate callback, which is used
      # to prepare data for each run.
      def populate
        return @populate unless block_given?

        @populate = Proc.new
      end
    end
  end
end
