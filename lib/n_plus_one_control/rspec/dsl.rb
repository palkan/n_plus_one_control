# frozen_string_literal: true

module NPlusOneControl
  module RSpec
    # Extends RSpec ExampleGroup with populate method
    module DSL
      # Setup populate callback, which is used
      # to prepare data for each run.
      def populate
        return @populate unless block_given?

        @populate = Proc.new
      end
    end
  end
end
