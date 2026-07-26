require "faraday"
require "addressable"
require "ipaddr"
require "namecheap/version"
require "namecheap/api/response"
require "namecheap/api/key_normalizer"

module Namecheap
  module API
    class Base
      SANDBOX = "https://api.sandbox.namecheap.com/xml.response"
      PRODUCTION = "https://api.namecheap.com/xml.response"
      PROTECTED_FIELDS = %w[api_user api_key user_name client_ip command].freeze

      def self.build_connection(open_timeout:, read_timeout:)
        Faraday.new do |connection|
          connection.options.open_timeout = open_timeout
          connection.options.timeout = read_timeout
          connection.request :url_encoded
        end
      end

      def initialize(config, connection:)
        @config = config
        @connection = connection
        @environment = config[:environment]
        @query = {
          "ApiUser" => config[:api_user],
          "ApiKey" => config[:api_key],
          "UserName" => config[:user_name],
          "ClientIp" => config[:client_ip]
        }
      end

      private

      def endpoint(command, params: {}, include_user_name: true)
        uri_template.expand("query" => request_params(command, params, include_user_name: include_user_name)).to_s
      end

      def request_params(command, params, include_user_name: true)
        raise ArgumentError, "params must be a hash" unless params.respond_to?(:each_pair)

        caller_params = params.each_pair.to_h do |key, value|
          normalized = KeyNormalizer.snake(key)
          if PROTECTED_FIELDS.include?(normalized)
            raise ArgumentError, "params cannot include protected parameter #{key}"
          end

          [key.to_s, value]
        end
        credentials = include_user_name ? @query : @query.except("UserName")
        caller_params.merge(credentials).merge("Command" => command)
      end

      def uri_template
        @uri_template ||= Addressable::Template.new("#{uri_endpoint}{?query*}")
      end

      def uri_endpoint
        (@environment == "production") ? PRODUCTION : SANDBOX
      end

      def build_and_get(command, params, include_user_name: true)
        url = endpoint(command, params: params, include_user_name: include_user_name)
        get(url, command)
      end

      def build_and_post(command, params, include_user_name: true)
        post(uri_endpoint, request_params(command, params, include_user_name: include_user_name), command)
      end

      def get(url, command)
        response = @connection.get(url)
        response_for(response, command)
      rescue Faraday::Error => error
        raise TransportError.new("Namecheap request failed: #{error.class}", command: command)
      end

      def post(url, params, command)
        response = @connection.post(url, params)
        response_for(response, command)
      rescue Faraday::Error => error
        raise TransportError.new("Namecheap request failed: #{error.class}", command: command)
      end

      def response_for(response, command)
        unless response.success?
          raise TransportError.new(
            "Namecheap returned HTTP #{response.status}",
            command: command,
            http_status: response.status
          )
        end

        Response.parse(response.body, command: command)
      end

      def required_string!(name, value)
        raise ArgumentError, "#{name} must be provided" if value.nil? || value == ""
        raise ArgumentError, "#{name} must be a string" unless value.is_a?(String)
        raise ArgumentError, "#{name} must not contain surrounding whitespace" unless value == value.strip

        value
      end

      def positive_integer!(name, value)
        raise ArgumentError, "#{name} must be a positive integer" unless value.is_a?(Integer) && value.positive?

        value
      end

      def boolean!(name, value)
        raise ArgumentError, "#{name} must be true or false" unless value == true || value == false

        value
      end

      def ipv4!(name, value)
        required_string!(name, value)
        address = IPAddr.new(value)
        raise ArgumentError, "#{name} must be an IPv4 address" unless address.ipv4?

        value
      rescue IPAddr::InvalidAddressError
        raise ArgumentError, "#{name} must be an IPv4 address"
      end
    end
  end
end
