require "faraday"
require "addressable"
require "namecheap/version"

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
        get(url)
      end

      def build_and_post(command, params, include_user_name: true)
        post(uri_endpoint, request_params(command, params, include_user_name: include_user_name))
      end

      def get(url)
        response = Faraday.get(url)
        response.body
      end

      def post(url, params)
        response = Faraday.post(url, params)
        response.body
      end
    end
  end
end
