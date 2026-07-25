require "namecheap/api/base"

module Namecheap
  module API
    class Transfers < Base
      def create(domain_name:, years:, epp_code:, params: {})
        required_string!(:domain_name, domain_name)
        positive_integer!(:years, years)
        required_string!(:epp_code, epp_code)
        command = "namecheap.domains.transfer.create"
        params = params.merge("DomainName" => domain_name, "Years" => years, "EPPCode" => epp_code)
        build_and_post(command, params)
      end

      def get_status(transfer_id:, params: {})
        positive_integer!(:transfer_id, transfer_id)
        command = "namecheap.domains.transfer.getStatus"
        params = params.merge("TransferID" => transfer_id)
        build_and_get(command, params)
      end

      def update_status(transfer_id:, resubmit:, params: {})
        positive_integer!(:transfer_id, transfer_id)
        boolean!(:resubmit, resubmit)
        command = "namecheap.domains.transfer.updateStatus"
        params = params.merge("TransferID" => transfer_id, "Resubmit" => resubmit)
        build_and_post(command, params)
      end

      def get_list(list_type: nil, search_term: nil, page: nil, page_size: nil, sort_by: nil, params: {})
        command = "namecheap.domains.transfer.getList"
        params = params.merge(
          {
            "ListType" => list_type,
            "SearchTerm" => search_term,
            "Page" => page,
            "PageSize" => page_size,
            "SortBy" => sort_by
          }.reject { |_, value| value.nil? }
        )
        build_and_get(command, params)
      end
    end
  end
end
