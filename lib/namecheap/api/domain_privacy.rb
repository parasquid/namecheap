require "namecheap/api/base"

module Namecheap
  module API
    class DomainPrivacy < Base
      def change_email_address(whoisguard_id:, params: {})
        positive_integer!(:whoisguard_id, whoisguard_id)
        command = "namecheap.whoisguard.changeemailaddress"
        params = params.merge("WhoisguardID" => whoisguard_id)
        build_and_post(command, params)
      end

      def enable(whoisguard_id:, forwarded_to_email:, params: {})
        positive_integer!(:whoisguard_id, whoisguard_id)
        required_string!(:forwarded_to_email, forwarded_to_email)
        command = "namecheap.whoisguard.enable"
        params = params.merge("WhoisguardID" => whoisguard_id, "ForwardedToEmail" => forwarded_to_email)
        build_and_post(command, params)
      end

      def disable(whoisguard_id:, params: {})
        positive_integer!(:whoisguard_id, whoisguard_id)
        command = "namecheap.whoisguard.disable"
        params = params.merge("WhoisguardID" => whoisguard_id)
        build_and_post(command, params)
      end

      def get_list(params: {})
        command = "namecheap.whoisguard.getList"
        build_and_get(command, params)
      end

      def renew(whoisguard_id:, years:, params: {})
        positive_integer!(:whoisguard_id, whoisguard_id)
        positive_integer!(:years, years)
        command = "namecheap.whoisguard.renew"
        params = params.merge("WhoisguardID" => whoisguard_id, "Years" => years)
        build_and_post(command, params)
      end
    end
  end
end
