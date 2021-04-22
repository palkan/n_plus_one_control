# frozen_string_literal: true

module NPlusOneControl
  class CollectorsRegistry
    class << self
      def register(collector_class)
        @collectors ||= {}
        @collectors[collector_class.key] = collector_class
      end

      def slice(*keys)
        raise ArgumentError, <<~MSG unless (keys & collectors.keys).size == keys.size
          No collectors for keys: #{keys.join(", ")}, exsiting collectors are: #{collectors.keys.join(", ")}
        MSG

        collectors.slice(*keys)
      end

      def get(key)
        collectors.fetch(key)
      end

      def unregister(*classes)
        classes.each { |klass| collectors.delete(klass.key) }
      end

      private

      attr_reader :collectors
    end
  end
end
