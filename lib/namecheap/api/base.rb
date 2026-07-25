require "faraday"
require "addressable"
require "namecheap/version"
require "namecheap/api/response"

module Namecheap
  module API
    class Base
      SANDBOX = "https://api.sandbox.namecheap.com/xml.response"
      PRODUCTION = "https://api.namecheap.com/xml.response"
      PROTECTED_FIELDS = %w[ApiUser ApiKey UserName ClientIp Command].freeze

      def initialize(config)
        @config = config
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
        caller_params = params.transform_keys(&:to_s).except(*PROTECTED_FIELDS)
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
        response = Faraday.get(url)
        response_for(response, command)
      rescue Faraday::Error => error
        raise TransportError.new("Namecheap request failed: #{error.class}", command: command)
      end

      def post(url, params, command)
        response = Faraday.post(url, params)
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
    end
  end
end
