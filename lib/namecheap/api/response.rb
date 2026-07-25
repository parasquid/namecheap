require "rexml/document"
require "namecheap/api/error"

module Namecheap
  module API
    class Response
      attr_reader :status,
        :requested_command,
        :data,
        :command_response,
        :paging,
        :warnings,
        :server,
        :gmt_time_difference,
        :execution_time,
        :raw_body

      def self.parse(raw_body, command:)
        document = REXML::Document.new(raw_body)
        root = document.root
        raise ParseError.new("empty API response", command: command, raw_body: raw_body) unless root

        new(root, raw_body: raw_body, command: command).tap(&:raise_for_error!)
      rescue REXML::ParseException => error
        raise ParseError.new("invalid XML response: #{error.message}", command: command, raw_body: raw_body)
      end

      def initialize(root, raw_body:, command:)
        @raw_body = raw_body
        @command = command
        @status = root.attributes["Status"].to_s
        @requested_command = text_at(root, ".//*[local-name()='RequestedCommand']") || command
        @warnings = messages_at(root, "Warning")
        @errors = messages_at(root, "Error")
        @server = text_at(root, ".//*[local-name()='Server']")
        @gmt_time_difference = text_at(root, ".//*[local-name()='GMTTimeDifference']")
        @execution_time = text_at(root, ".//*[local-name()='ExecutionTime']")

        command_node = REXML::XPath.first(root, ".//*[local-name()='CommandResponse']")
        result_node = command_node && REXML::XPath.first(command_node, ".//*[contains(local-name(), 'Result')]")
        paging_node = command_node && REXML::XPath.first(command_node, ".//*[local-name()='Paging']")
        @command_response = command_node ? self.class.element(command_node) : {}
        @data = result_node ? self.class.element(result_node) : @command_response
        @paging = paging_node ? self.class.element(paging_node) : nil
      end

      def success?
        status.casecmp?("OK") && @errors.empty?
      end

      def to_h
        {
          status: status,
          requested_command: requested_command,
          data: data,
          command_response: command_response,
          paging: paging,
          warnings: warnings,
          server: server,
          gmt_time_difference: gmt_time_difference,
          execution_time: execution_time
        }.compact
      end

      def raise_for_error!
        return self if success?

        errors = @errors
        errors = [{message: "Namecheap API returned an error"}] if errors.empty?
        raise ApiError.new(errors: errors, response: self, command: @command)
      end

      def self.element(node)
        children = node.elements.to_a
        attributes = node.attributes.to_h.to_h { |key, value| [snake(key), scalar(value)] }
        return scalar(node.text) if children.empty? && attributes.empty? && node.text
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
          .to_sym
      end

      def self.scalar(value)
        value = value.to_s
        case value
        when /\Atrue\z/i then true
        when /\Afalse\z/i then false
        when /\A-?(0|[1-9]\d*)\z/ then value.to_i
        else value
        end
      end

      private

      def messages_at(root, name)
        REXML::XPath.match(root, ".//*[local-name()='#{name}']").map do |element|
          {
            code: element.attributes["Number"]&.to_s,
            message: element.text.to_s.strip
          }.compact
        end
      end

      def text_at(root, xpath)
        REXML::XPath.first(root, xpath)&.text&.to_s
      end
    end
  end
end
