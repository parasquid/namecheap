require "namecheap/api/response"

module Namecheap
  module CLI
    module XML
      def self.parse(response)
        unless response.is_a?(Namecheap::API::Response)
          raise Error.new("expected a Namecheap API response", exit_code: 1)
        end

        stringify_keys(response.data)
      end

      def self.stringify_keys(value)
        case value
        when Hash
          value.to_h { |key, child| [key.to_s, stringify_keys(child)] }
        when Array
          value.map { |child| stringify_keys(child) }
        else
          value
        end
      end
    end
  end
end
