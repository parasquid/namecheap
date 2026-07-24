require "rexml/document"

module Namecheap
  module CLI
    module XML
      def self.parse(body)
        document = REXML::Document.new(body)
        response = document.root
        raise Error.new("empty API response", exit_code: 1) unless response

        errors = REXML::XPath.match(response, ".//*[local-name()='Error']").map(&:text).compact
        if response.attributes["Status"] == "ERROR" || errors.any?
          raise Error.new(errors.join("; ").empty? ? "Namecheap API returned an error" : errors.join("; "), exit_code: 1)
        end

        result = REXML::XPath.first(response, ".//*[contains(local-name(), 'Result')]")
        element(result || response)
      rescue REXML::ParseException => error
        raise Error.new("invalid XML response: #{error.message}", exit_code: 1)
      end

      def self.element(node)
        children = node.elements.to_a
        attributes = node.attributes.to_h.to_h { |key, value| [snake(key), scalar(value)] }
        return attributes unless children.any?

        grouped = children.group_by { |child| local_name(child.name) }
        values = grouped.to_h do |name, nodes|
          converted = nodes.map { |child| element(child) }
          [snake(name), (converted.length == 1) ? converted.first : converted]
        end
        attributes.each { |key, value| values[key] = value }
        values
      end

      def self.local_name(name)
        name.to_s.split(":").last
      end

      def self.snake(value)
        value.to_s
          .gsub(/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
          .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
          .tr("-", "_")
          .downcase
      end

      def self.scalar(value)
        value = value.to_s
        case value
        when /\Atrue\z/i then true
        when /\Afalse\z/i then false
        when /\A-?\d+\z/ then value.to_i
        else value
        end
      end
    end
  end
end
