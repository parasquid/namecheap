require "rexml/document"
require "rexml/formatters/default"
require "rexml/xpath"
require "namecheap/api/key_normalizer"

module Namecheap
  module CLI
    class SensitiveData
      REDACTED = "[redacted]"
      FIELD_NAMES = %w[
        api_key
        password
        old_password
        new_password
        new_user_password
        epp_code
        auth_code
        authorization_code
        reset_code
        token
        token_id
      ].freeze

      class UnsafeOutputError < StandardError
      end

      def initialize
        @values = []
      end

      def register(value)
        discover(value)
        value
      end

      def redact(value)
        discover(value)
        redact_value(value)
      end

      def redact_text(value)
        @values.sort_by { |secret| -secret.length }.reduce(value.to_s) do |text, secret|
          text.gsub(secret, REDACTED)
        end
      end

      def redact_xml(value)
        document = REXML::Document.new(value.to_s)
        discover_xml(document)
        changed = redact_xml_nodes(document)
        return value unless changed

        output = +""
        REXML::Formatters::Default.new.write(document, output)
        output
      rescue REXML::ParseException
        raise UnsafeOutputError, "raw API response could not be safely inspected"
      end

      private

      def sensitive_field?(name)
        FIELD_NAMES.include?(Namecheap::API::KeyNormalizer.snake(name))
      end

      def discover(value)
        case value
        when Hash
          value.each do |key, child|
            register_value(child) if sensitive_field?(key)
            discover(child)
          end
        when Array
          value.each { |child| discover(child) }
        end
      end

      def register_value(value)
        case value
        when Hash
          value.each_value { |child| register_value(child) }
        when Array
          value.each { |child| register_value(child) }
        when String, Numeric
          secret = value.to_s
          @values << secret unless secret.empty? || secret == REDACTED || @values.include?(secret)
        end
      end

      def redact_value(value)
        case value
        when Hash
          value.to_h do |key, child|
            [key, sensitive_field?(key) ? REDACTED : redact_value(child)]
          end
        when Array
          value.map { |child| redact_value(child) }
        when String
          redact_text(value)
        else
          value
        end
      end

      def discover_xml(document)
        REXML::XPath.each(document, "//*") do |element|
          element.attributes.each_attribute do |attribute|
            register_value(attribute.value) if sensitive_field?(attribute.name)
          end
          register_value(element_text(element)) if sensitive_field?(element.name)
        end
      end

      def element_text(element)
        element.children.filter_map { |child| child.value if child.is_a?(REXML::Text) }.join
      end

      def redact_xml_nodes(document)
        changed = false
        REXML::XPath.each(document, "//*") do |element|
          element.attributes.each_attribute do |attribute|
            replacement = sensitive_field?(attribute.name) ? REDACTED : redact_text(attribute.value)
            next if replacement == attribute.value

            element.attributes[attribute.name] = replacement
            changed = true
          end

          if sensitive_field?(element.name)
            element.children.to_a.each { |child| element.delete(child) }
            element.add_text(REDACTED)
            changed = true
          else
            element.children.grep(REXML::Text).each do |text|
              replacement = redact_text(text.value)
              next if replacement == text.value

              text.value = replacement
              changed = true
            end
          end
        end
        changed
      end
    end
  end
end
