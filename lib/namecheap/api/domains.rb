require "namecheap/api/base"
require "namecheap/api/dns"

module Namecheap
  module API
    class Domains < Base
      # https://www.namecheap.com/support/api/methods/domains/create.aspx
      def create(
        domain_name:,
        years:,
        registrant_first_name:,
        registrant_last_name:,
        registrant_address_1:,
        registrant_city:,
        registrant_state_province:,
        registrant_postal_code:,
        registrant_country:,
        registrant_phone:,
        registrant_email_address:,
        params: {}
      )
        command = "namecheap.domains.create".freeze

      end

      # https://www.namecheap.com/support/api/methods/domains/get-list.aspx
      def get_list(params: {})
        command = "namecheap.domains.getList".freeze
        build_and_get command, params
      end

      # https://www.namecheap.com/support/api/methods/domains/get-contacts.aspx
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