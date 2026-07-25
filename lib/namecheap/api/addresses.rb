require "namecheap/api/base"

module Namecheap
  module API
    class Addresses < Base
      ADDRESS_FIELDS = {
        email_address: "EmailAddress",
        first_name: "FirstName",
        last_name: "LastName",
        job_title: "JobTitle",
        organization: "Organization",
        address_1: "Address1",
        address_2: "Address2",
        city: "City",
        state_province: "StateProvince",
        state_province_choice: "StateProvinceChoice",
        postal_code: "Zip",
        country: "Country",
        phone: "Phone",
        phone_ext: "PhoneExt",
        fax: "Fax"
      }.freeze
      REQUIRED_ADDRESS_FIELDS = %i[
        email_address
        first_name
        last_name
        address_1
        city
        state_province
        state_province_choice
        postal_code
        country
        phone
      ].freeze

      def create(address_name:, address:, default: false, params: {})
        required_string!(:address_name, address_name)
        boolean!(:default, default)
        command = "namecheap.users.address.create"
        params = params
          .merge(address_params(address))
          .merge("AddressName" => address_name, "DefaultYN" => boolean_number(default))
        build_and_post(command, params)
      end

      def delete(address_id:, params: {})
        positive_integer!(:address_id, address_id)
        command = "namecheap.users.address.delete"
        build_and_post(command, params.merge("AddressId" => address_id))
      end

      def get_info(address_id:, params: {})
        positive_integer!(:address_id, address_id)
        command = "namecheap.users.address.getInfo"
        build_and_get(command, params.merge("AddressId" => address_id))
      end

      def get_list(params: {})
        command = "namecheap.users.address.getList"
        build_and_get(command, params)
      end

      def set_default(address_id:, params: {})
        positive_integer!(:address_id, address_id)
        command = "namecheap.users.address.setDefault"
        build_and_post(command, params.merge("AddressId" => address_id))
      end

      def update(address_id:, address_name:, address:, default: nil, params: {})
        positive_integer!(:address_id, address_id)
        required_string!(:address_name, address_name)
        boolean!(:default, default) unless default.nil?
        command = "namecheap.users.address.update"
        params = params
          .merge(address_params(address))
          .merge("AddressId" => address_id, "AddressName" => address_name)
        params["DefaultYN"] = boolean_number(default) unless default.nil?
        build_and_post(command, params)
      end

      private

      def address_params(address)
        raise ArgumentError, "address must be a hash" unless address.respond_to?(:transform_keys)

        address = address.transform_keys(&:to_sym)
        unknown = address.keys - ADDRESS_FIELDS.keys
        raise ArgumentError, "address contains unknown field #{unknown.first}" if unknown.any?

        missing = REQUIRED_ADDRESS_FIELDS.find { |field| blank?(address[field]) }
        raise ArgumentError, "address.#{missing} must be provided" if missing

        address.to_h { |field, value| [ADDRESS_FIELDS.fetch(field), value] }
      end

      def boolean_number(value)
        return 1 if value == true
        return 0 if value == false

        raise ArgumentError, "default must be true or false"
      end

      def blank?(value)
        value.nil? || value.to_s.empty?
      end
    end
  end
end
