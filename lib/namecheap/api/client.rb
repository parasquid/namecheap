require "namecheap/api/domains"
require "namecheap/api/domain_privacy"
require "namecheap/api/ssl"
require "namecheap/api/users"

module Namecheap
  module API
    class Client
      ENVIRONMENTS = %w[sandbox production].freeze

      attr_reader :config

      def initialize(
        api_user:,
        api_key:,
        client_ip:,
        user_name: api_user,
        environment: "sandbox"
      )
        validate_presence!(api_user: api_user, api_key: api_key, user_name: user_name, client_ip: client_ip)
        validate_environment!(environment)

        @config = {
          api_user: api_user,
          api_key: api_key,
          user_name: user_name,
          client_ip: client_ip,
          environment: environment
        }.freeze
      end

      def domains
        Domains.new(@config)
      end

      def ssl
        Ssl.new(@config)
      end

      def users
        Users.new(@config)
      end

      def domain_privacy
        DomainPrivacy.new(@config)
      end

      private

      def validate_presence!(options)
        missing = options.find { |_, value| value.nil? || value.to_s.empty? }
        raise ArgumentError, "#{missing.first} must be provided" if missing
      end

      def validate_environment!(environment)
        return if ENVIRONMENTS.include?(environment)

        raise ArgumentError, "environment must be sandbox or production"
      end
    end
  end
end
