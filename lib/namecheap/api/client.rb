require "namecheap/api/domains"

module Namecheap
  module API
    class Client
      attr_accessor :config
      def initialize(
        api_user:, api_key:,

        # optional params
        user_name: api_user,
        client_ip: "0.0.0.0",
        environment: "sandbox"
      )
        @config = {
          api_user: api_user,
          api_key: api_key,
          user_name: user_name,
          client_ip: client_ip,
          environment: environment
        }
      end

      def domains
        Domains.new(@config)
      end

      def ssl
      end

      def users
      end

      def whoisguard
      end
    end
  end
end
