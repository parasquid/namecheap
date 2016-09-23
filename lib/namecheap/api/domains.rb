require "namecheap/api/base"
require "namecheap/api/dns"

module Namecheap
  module API
    class Domains < Base
      COMMAND = "namecheap.domains.get_contacts"

      def get_contacts(domain:)
      end

      def dns
        Dns.new(@config)
      end
    end
  end
end