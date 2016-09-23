require "namecheap/api/base"
require "namecheap/api/dns"

module Namecheap
  module API
    class Domains < Base

      def get_list(optional_params: {})
        command = "namecheap.domains.getList".freeze
        params = optional_params
        build_and_get command, params
      end

      def get_contacts(domain_name:)
        command = "namecheap.domains.getContacts".freeze
        params = {"DomainName" => domain_name}
        build_and_get command, params
      end

      def dns
        Dns.new(@config)
      end
    end
  end
end