require "faraday"
require "addressable"
require "faraday"

module Namecheap
  module API
    class Base
      SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'.freeze
      PRODUCTION = 'https://api.namecheap.com/xml.response'.freeze

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

      def endpoint(command, params: {})
        uri_template.expand({
          "query" => @query.merge({
            "Command" => command
          }).merge(params)
        }).to_s
      end

      def uri_template
        @uri_template ||= Addressable::Template.new("#{uri_endpoint}{?query*}")
      end

      def uri_endpoint
        @environment == "production" ? PRODUCTION : SANDBOX
      end

      def execute(url)
        response = Faraday.get url
        response.body
      end

    end
  end
end