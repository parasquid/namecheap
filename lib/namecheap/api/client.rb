require "namecheap/api/domains"

module Namecheap
  module API
    class Client
      def initialize(api_user:, api_key:, user_name: nil, client_ip: nil)
        @config = {
          api_user: api_user,
          api_key: api_user,
          user_name: user_name || api_user,
          client_ip: client_ip || "0.0.0.0"
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
