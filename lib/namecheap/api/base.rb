require "faraday"
require "addressable"

module Namecheap
  module API
    class Base
      SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'
      PRODUCTION = 'https://api.namecheap.com/xml.response'
      ENVIRONMENT = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : (ENV["RACK_ENV"] || 'development')
      ENDPOINT = (ENVIRONMENT == 'production' ? PRODUCTION : SANDBOX)
      URI_TEMPLATE = Addressable::Template.new("#{ENDPOINT}{?query*}")

      def initialize(config)
        @config = config
        @query = {
          "ApiUser" => config[:api_user],
          "ApiKey" => config[:api_key],
          "UserName" => config[:user_name],
          "ClientIp" => config[:client_ip]
        }
      end

      def endpoint(command:, params: {})
        URI_TEMPLATE.expand({
          "query" => @query.merge({
            "Command" => command
          }).merge(params)
        }).to_s
      end
    end
  end
end