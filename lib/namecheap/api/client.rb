require "namecheap/api/domains"
require "namecheap/api/domain_privacy"
require "namecheap/api/ssl"
require "namecheap/api/users"
require "ipaddr"

module Namecheap
  module API
    class Client
      ENVIRONMENTS = %w[sandbox production].freeze

      attr_reader :environment

      def initialize(
        api_user:,
        api_key:,
        client_ip:,
        user_name: api_user,
        environment: "sandbox"
      )
        validate_strings!(api_user: api_user, api_key: api_key, user_name: user_name, client_ip: client_ip)
        validate_ipv4!(client_ip)
        validate_environment!(environment)

        @config = {
          api_user: immutable_string(api_user),
          api_key: immutable_string(api_key),
          user_name: immutable_string(user_name),
          client_ip: immutable_string(client_ip),
          environment: immutable_string(environment)
        }.freeze
        @environment = @config.fetch(:environment)
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

      def validate_strings!(options)
        options.each do |name, value|
          raise ArgumentError, "#{name} must be a string" unless value.is_a?(String)
          raise ArgumentError, "#{name} must be provided" if value.empty?
          raise ArgumentError, "#{name} must not contain surrounding whitespace" unless value == value.strip
        end
      end

      def validate_ipv4!(value)
        address = IPAddr.new(value)
        raise ArgumentError, "client_ip must be an IPv4 address" unless address.ipv4?
      rescue IPAddr::InvalidAddressError
        raise ArgumentError, "client_ip must be an IPv4 address"
      end

      def validate_environment!(environment)
        raise ArgumentError, "environment must be a string" unless environment.is_a?(String)
        return if ENVIRONMENTS.include?(environment)

        raise ArgumentError, "environment must be sandbox or production"
      end

      def immutable_string(value)
        value.dup.freeze
      end
    end
  end
end
