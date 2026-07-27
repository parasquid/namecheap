require "json"
require "namecheap/cli/sensitive_data"

module Namecheap
  module CLI
    class Renderer
      def initialize(io:, format:, sensitive_data: SensitiveData.new)
        @io = io
        @format = format
        @sensitive_data = sensitive_data
      end

      def render(data, meta: {}, raw_xml: false)
        if raw_xml
          @io.puts(@sensitive_data.redact_xml(data))
          return
        end

        output = @sensitive_data.redact("data" => data, "meta" => meta)
        case @format
        when :raw
          @io.puts(output.fetch("data"))
        when :json
          @io.puts(JSON.pretty_generate(output))
        else
          human(output.fetch("data"))
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
