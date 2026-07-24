require "json"

module Namecheap
  module CLI
    class Renderer
      def initialize(io:, format:)
        @io = io
        @format = format
      end

      def render(data, meta: {})
        case @format
        when :raw
          @io.puts(data)
        when :json
          @io.puts(JSON.pretty_generate("data" => data, "meta" => meta))
        else
          human(data)
        end
      end

      private

      def human(value, prefix = nil)
        case value
        when Array
          value.each { |item| human(item, prefix) }
        when Hash
          if value.values.none? { |item| item.is_a?(Hash) || item.is_a?(Array) }
            value.each { |key, item| @io.puts("#{label(key)}: #{item}") }
            @io.puts if prefix
          else
            value.each { |key, item| human(item, label(key)) }
          end
        else
          @io.puts(prefix ? "#{prefix}: #{value}" : value)
        end
      end

      def label(value)
        value.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
