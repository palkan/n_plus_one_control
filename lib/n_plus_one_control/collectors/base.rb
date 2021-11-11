# frozen_string_literal: true

module NPlusOneControl
  module Collectors
    class Base
      class << self
        attr_accessor :key, :event, :name

        def failure_message(type, queries)
          msg = ["#{::NPlusOneControl::FAILURE_MESSAGES[type]} to #{name || key.to_s.upcase}, but got:\n"]
          queries.each do |(scale, data)|
            msg << "  #{data[key].size} for N=#{scale}\n"
          end
          msg.join
        end
      end

      def initialize(pattern)
        @pattern = pattern
        @queries = []
      end

      def subscribe
        event = self.class.event.respond_to?(:call) ? self.class.event.call : self.class.event
        @subscriber = ActiveSupport::Notifications.subscribe(event, method(:callback))
      end

      def reset
        unsubscribe
        @queries = []
      end

      def callback
        raise NotImplementedError
      end

      private

      def unsubscribe
        ActiveSupport::Notifications.unsubscribe(@subscriber)
      end
    end
  end
end
