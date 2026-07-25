module Namecheap
  module API
    class Error < StandardError
      attr_reader :command

      def initialize(message, command: nil)
        @command = command
        super(message)
      end
    end

    class ApiError < Error
      attr_reader :errors, :response

      def initialize(errors:, response:, command: nil)
        @errors = errors
        @response = response
        message = errors.map { |error| [error[:code], error[:message]].compact.join(": ") }.join("; ")
        super(message.empty? ? "Namecheap API returned an error" : message, command: command)
      end
    end

    class TransportError < Error
      attr_reader :http_status

      def initialize(message, command:, http_status: nil)
        @http_status = http_status
        super(message, command: command)
      end
    end

    class ParseError < Error
      attr_reader :raw_body

      def initialize(message, command:, raw_body:)
        @raw_body = raw_body
        super(message, command: command)
      end
    end
  end
end
