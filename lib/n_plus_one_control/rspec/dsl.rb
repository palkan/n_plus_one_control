# frozen_string_literal: true

module NPlusOneControl
  module RSpec
    # Includes scale method into RSpec Example
    module DSL
      # Extends RSpec ExampleGroup with populate & warmup methods
      module ClassMethods
        # Setup warmup block, which will run before matching
        # for example, if using cache, then later queries
        # will perform less DB queries than first
        def warmup(&block)
          return @warmup unless block

          @warmup = block
        end

        # Setup populate callback, which is used
        # to prepare data for each run.
        def populate(&block)
          return @populate unless block

          @populate = block
        end
      end

      attr_accessor :executor

      def current_scale
        executor&.current_scale
      end
    end
  end
end
