require "namecheap/api/base"

module Namecheap
  module API
    class Transfers < Base
      def create(domain_name:, years:, epp_code:, params: {})
        command = "namecheap.domains.transfer.create"
        params = params.merge("DomainName" => domain_name, "Years" => years, "EPPCode" => epp_code)
        build_and_post(command, params)
      end

      def get_status(transfer_id:, params: {})
        command = "namecheap.domains.transfer.getStatus"
        params = params.merge("TransferID" => transfer_id)
        build_and_get(command, params)
      end

      def update_status(transfer_id:, resubmit:, params: {})
        command = "namecheap.domains.transfer.updateStatus"
        params = params.merge("TransferID" => transfer_id, "Resubmit" => resubmit)
        build_and_post(command, params)
      end

      def get_list(params: {})
        command = "namecheap.domains.transfer.getList"
        build_and_get(command, params)
      end
    end
  end
end
