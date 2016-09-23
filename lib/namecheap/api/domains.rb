require "namecheap/api/base"
require "namecheap/api/dns"

module Namecheap
  module API
    class Domains < Base

      def get_contacts(domain_name:)
        command = "namecheap.domains.getContacts".freeze
        url = endpoint(command, params: {"DomainName" => domain_name})
        execute url
      end

      def dns
        Dns.new(@config)
      end
    end
  end
end