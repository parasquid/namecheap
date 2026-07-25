require "namecheap/api/base"
require "namecheap/api/addresses"

module Namecheap
  module API
    class Users < Base
      PROFILE_FIELDS = {
        first_name: "FirstName",
        last_name: "LastName",
        job_title: "JobTitle",
        organization: "Organization",
        address_1: "Address1",
        address_2: "Address2",
        city: "City",
        state_province: "StateProvince",
        postal_code: "Zip",
        country: "Country",
        email_address: "EmailAddress",
        phone: "Phone",
        phone_ext: "PhoneExt",
        fax: "Fax"
      }.freeze
      REQUIRED_PROFILE_FIELDS = %i[
        first_name
        last_name
        address_1
        city
        state_province
        postal_code
        country
        email_address
        phone
      ].freeze

      # https://www.namecheap.com/support/api/methods/users/get-pricing/
      def get_pricing(
        product_type:,
        product_category: nil,
        promotion_code: nil,
        action_name: nil,
        product_name: nil,
        params: {}
      )
        command = "namecheap.users.getPricing"
        params = params
          .merge(
            {
              "ProductCategory" => product_category,
              "PromotionCode" => promotion_code,
              "ActionName" => action_name,
              "ProductName" => product_name
            }.reject { |_, value| value.nil? }
          )
          .merge("ProductType" => product_type)
        build_and_get(command, params)
      end

      def get_balances(params: {})
        command = "namecheap.users.getBalances"
        build_and_get(command, params)
      end

      def create(user_name:, password:, profile:, accept_terms:, params: {})
        command = "namecheap.users.create"
        params = params
          .merge(profile_params(profile))
          .merge(
            "NewUserName" => user_name,
            "NewUserPassword" => password,
            "AcceptTerms" => accept_terms
          )
        build_and_post(command, params)
      end

      def update(profile:, params: {})
        command = "namecheap.users.update"
        params = params.merge(profile_params(profile))
        build_and_post(command, params)
      end

      def change_password(new_password:, old_password: nil, reset_code: nil, params: {})
        modes = [old_password, reset_code].count { |value| !blank?(value) }
        raise ArgumentError, "provide exactly one of old_password or reset_code" unless modes == 1

        command = "namecheap.users.changePassword"
        params = params.merge("NewPassword" => new_password)
        if reset_code
          params = params.merge("ResetCode" => reset_code)
          build_and_post(command, params, include_user_name: false)
        else
          params = params.merge("OldPassword" => old_password)
          build_and_post(command, params)
        end
      end

      def create_add_funds_request(user_name:, payment_type:, amount:, return_url:, params: {})
        command = "namecheap.users.createaddfundsrequest"
        params = params.merge(
          "Username" => user_name,
          "PaymentType" => payment_type,
          "Amount" => amount,
          "ReturnUrl" => return_url
        )
        build_and_post(command, params)
      end

      def get_add_funds_status(token_id:, params: {})
        command = "namecheap.users.getAddFundsStatus"
        params = params.merge("TokenId" => token_id)
        build_and_get(command, params)
      end

      def login(password:, params: {})
        command = "namecheap.users.login"
        params = params.merge("Password" => password)
        build_and_post(command, params)
      end

      def reset_password(find_by:, find_by_value:, params: {})
        command = "namecheap.users.resetPassword"
        params = params.merge("FindBy" => find_by, "FindByValue" => find_by_value)
        build_and_post(command, params, include_user_name: false)
      end

      def addresses
        Addresses.new(@config)
      end

      private

      def profile_params(profile)
        raise ArgumentError, "profile must be a hash" unless profile.respond_to?(:transform_keys)

        profile = profile.transform_keys(&:to_sym)
        unknown = profile.keys - PROFILE_FIELDS.keys
        raise ArgumentError, "profile contains unknown field #{unknown.first}" if unknown.any?

        missing = REQUIRED_PROFILE_FIELDS.find { |field| blank?(profile[field]) }
        raise ArgumentError, "profile.#{missing} must be provided" if missing

        profile.to_h { |field, value| [PROFILE_FIELDS.fetch(field), value] }
      end

      def blank?(value)
        value.nil? || value.to_s.empty?
      end
    end
  end
end
