require "namecheap/api/base"
require "namecheap/api/dns"

module Namecheap
  module API
    class Domains < Base
      def get_contacts(domain:)
        command = "namecheap.domains.get_contacts"
      end

      def dns
        Dns.new(@config)
      end
    end
  end
end