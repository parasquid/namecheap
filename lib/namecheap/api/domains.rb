require "namecheap/api/base"
require "namecheap/api/dns"
require "namecheap/api/nameservers"
require "namecheap/api/transfers"

module Namecheap
  module API
    class Domains < Base
      CONTACT_FIELDS = {
        organization_name: "OrganizationName",
        job_title: "JobTitle",
        first_name: "FirstName",
        last_name: "LastName",
        address_1: "Address1",
        address_2: "Address2",
        city: "City",
        state_province: "StateProvince",
        state_province_choice: "StateProvinceChoice",
        postal_code: "PostalCode",
        country: "Country",
        phone: "Phone",
        phone_ext: "PhoneExt",
        fax: "Fax",
        email_address: "EmailAddress"
      }.freeze
      REQUIRED_CONTACT_FIELDS = %i[
        first_name
        last_name
        address_1
        city
        state_province
        postal_code
        country
        phone
        email_address
      ].freeze

      # https://www.namecheap.com/support/api/methods/domains/create/
      def create(
        domain_name:,
        years:,
        registrant:,
        tech:,
        admin:,
        aux_billing:,
        idn_code: nil,
        add_free_domain_privacy: nil,
        domain_privacy_enabled: nil,
        premium_domain: nil,
        premium_price: nil,
        eap_fee: nil,
        params: {}
      )
        command = "namecheap.domains.create"
        params = params
          .merge(contact_params("Registrant", registrant))
          .merge(contact_params("Tech", tech))
          .merge(contact_params("Admin", admin))
          .merge(contact_params("AuxBilling", aux_billing))
          .merge(optional_params(
            "IdnCode" => idn_code,
            "AddFreeWhoisguard" => add_free_domain_privacy,
            "WGEnabled" => domain_privacy_enabled,
            "IsPremiumDomain" => premium_domain,
            "PremiumPrice" => premium_price,
            "EapFee" => eap_fee
          ))
          .merge("DomainName" => domain_name, "Years" => years)
        build_and_post(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/get-list/
      def get_list(list_type: nil, search_term: nil, page: nil, page_size: nil, sort_by: nil, params: {})
        command = "namecheap.domains.getList"
        params = params.merge(optional_params(
          "ListType" => list_type,
          "SearchTerm" => search_term,
          "Page" => page,
          "PageSize" => page_size,
          "SortBy" => sort_by
        ))
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/get-contacts/
      def get_contacts(domain_name:, params: {})
        command = "namecheap.domains.getContacts"
        params = params.merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/get-tld-list/
      def get_tld_list(params: {})
        command = "namecheap.domains.getTldList"
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/set-contacts/
      def set_contacts(domain_name:, registrant:, tech:, admin:, aux_billing:, params: {})
        command = "namecheap.domains.setContacts"
        params = params
          .merge(contact_params("Registrant", registrant))
          .merge(contact_params("Tech", tech))
          .merge(contact_params("Admin", admin))
          .merge(contact_params("AuxBilling", aux_billing))
          .merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/check/
      def check(domain_names:, params: {})
        command = "namecheap.domains.check"
        domains = list_values(domain_names, name: "domain_names")
        raise ArgumentError, "domain_names cannot contain more than 50 domains" if domains.length > 50

        params = params.merge("DomainList" => domains.join(","))
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/reactivate/
      def reactivate(domain_name:, years_to_add: nil, premium_price: nil, params: {})
        command = "namecheap.domains.reactivate"
        params = params
          .merge(optional_params("YearsToAdd" => years_to_add, "PremiumPrice" => premium_price))
          .merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/renew/
      def renew(domain_name:, years:, premium_price: nil, params: {})
        command = "namecheap.domains.renew"
        params = params
          .merge(optional_params("PremiumPrice" => premium_price))
          .merge("DomainName" => domain_name, "Years" => years)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/get-registrar-lock/
      def get_registrar_lock(domain_name:, params: {})
        command = "namecheap.domains.getRegistrarLock"
        params = params.merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/set-registrar-lock/
      def set_registrar_lock(domain_name:, params: {})
        command = "namecheap.domains.setRegistrarLock"
        params = params.merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains/get-info/
      def get_info(domain_name:, host_name: nil, params: {})
        command = "namecheap.domains.getInfo"
        params = params
          .merge(optional_params("HostName" => host_name))
          .merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      def dns
        Dns.new(@config)
      end

      def nameservers
        Nameservers.new(@config)
      end

      def transfers
        Transfers.new(@config)
      end

      private

      def contact_params(prefix, contact)
        contact = normalized_hash(contact, name: prefix)
        unknown = contact.keys - CONTACT_FIELDS.keys
        raise ArgumentError, "#{prefix} contains unknown field #{unknown.first}" if unknown.any?

        missing = REQUIRED_CONTACT_FIELDS.find { |field| blank?(contact[field]) }
        raise ArgumentError, "#{prefix}.#{missing} must be provided" if missing

        contact.to_h do |field, value|
          ["#{prefix}#{CONTACT_FIELDS.fetch(field)}", value]
        end
      end

      def normalized_hash(value, name:)
        raise ArgumentError, "#{name} must be a hash" unless value.respond_to?(:transform_keys)

        value.transform_keys(&:to_sym)
      end

      def list_values(value, name:)
        values = if value.is_a?(String)
          value.split(",")
        elsif value.is_a?(Array)
          value
        else
          raise ArgumentError, "#{name} must be a string or array"
        end

        values = values.map { |item| item.to_s.strip }.reject(&:empty?)
        raise ArgumentError, "#{name} must contain at least one value" if values.empty?

        values
      end

      def blank?(value)
        value.nil? || value.to_s.empty?
      end

      def optional_params(values)
        values.reject { |_, value| value.nil? }
      end
    end
  end
end
