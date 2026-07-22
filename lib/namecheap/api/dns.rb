require "namecheap/api/base"

module Namecheap
  module API
    class Dns < Base
      RECORD_FIELDS = {
        host_name: "HostName",
        record_type: "RecordType",
        address: "Address",
        mx_pref: "MXPref",
        ttl: "TTL"
      }.freeze
      REQUIRED_RECORD_FIELDS = %i[host_name record_type address].freeze
      FORWARDING_FIELDS = {
        mailbox: "MailBox",
        forward_to: "ForwardTo"
      }.freeze

      # https://www.namecheap.com/support/api/methods/domains-dns/set-default/
      def set_default(sld:, tld:, params: {})
        command = "namecheap.domains.dns.setDefault"
        params = params.merge("SLD" => sld, "TLD" => tld)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains-dns/set-custom/
      def set_custom(sld:, tld:, nameservers:, params: {})
        command = "namecheap.domains.dns.setCustom"
        nameservers = list_values(nameservers, name: "nameservers")
        params = params.merge("SLD" => sld, "TLD" => tld, "Nameservers" => nameservers.join(","))
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains-dns/get-list/
      def get_list(sld:, tld:, params: {})
        command = "namecheap.domains.dns.getList"
        params = params.merge(
          "SLD" => sld,
          "TLD" => tld
        )
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains-dns/get-hosts/
      def get_hosts(sld:, tld:, params: {})
        command = "namecheap.domains.dns.getHosts"
        params = params.merge("SLD" => sld, "TLD" => tld)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains-dns/get-email-forwarding/
      def get_email_forwarding(domain_name:, params: {})
        command = "namecheap.domains.dns.getEmailForwarding"
        params = params.merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # https://www.namecheap.com/support/api/methods/domains-dns/set-email-forwarding/
      def set_email_forwarding(domain_name:, forwardings:, params: {})
        command = "namecheap.domains.dns.setEmailForwarding"
        params = params
          .merge(indexed_params(forwardings, fields: FORWARDING_FIELDS, required: FORWARDING_FIELDS.keys, name: "forwardings"))
          .merge("DomainName" => domain_name)
        build_and_get(command, params)
      end

      # Replaces the complete host-record set for the domain.
      # https://www.namecheap.com/support/api/methods/domains-dns/set-hosts/
      def set_hosts(sld:, tld:, email_type:, records:, params: {})
        raise ArgumentError, "email_type must be provided" if blank?(email_type)

        command = "namecheap.domains.dns.setHosts"
        record_params = indexed_params(records, fields: RECORD_FIELDS, required: REQUIRED_RECORD_FIELDS, name: "records") do |record, index|
          if record[:record_type].to_s.upcase == "MX" && blank?(record[:mx_pref])
            raise ArgumentError, "records[#{index}].mx_pref must be provided for MX records"
          end
        end
        params = params.merge(record_params).merge("SLD" => sld, "TLD" => tld, "EmailType" => email_type)
        build_and_post(command, params)
      end

      private

      def indexed_params(values, fields:, required:, name:)
        raise ArgumentError, "#{name} must be a non-empty array" unless values.is_a?(Array) && values.any?

        values.each_with_index.with_object({}) do |(value, zero_based_index), result|
          index = zero_based_index + 1
          value = normalized_hash(value, name: "#{name}[#{zero_based_index}]")
          unknown = value.keys - fields.keys
          raise ArgumentError, "#{name}[#{zero_based_index}] contains unknown field #{unknown.first}" if unknown.any?

          missing = required.find { |field| blank?(value[field]) }
          raise ArgumentError, "#{name}[#{zero_based_index}].#{missing} must be provided" if missing

          yield(value, zero_based_index) if block_given?
          value.each do |field, field_value|
            result["#{fields.fetch(field)}#{index}"] = field_value
          end
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
    end
  end
end
