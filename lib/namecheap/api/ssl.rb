require "namecheap/api/base"

module Namecheap
  module API
    class Ssl < Base
      def create(years:, certificate_type:, params: {})
        positive_integer!(:years, years)
        required_string!(:certificate_type, certificate_type)
        command = "namecheap.ssl.create"
        params = params.merge("Years" => years, "Type" => certificate_type)
        build_and_post(command, params)
      end

      def get_list(list_type: nil, search_term: nil, page: nil, page_size: nil, sort_by: nil, params: {})
        command = "namecheap.ssl.getList"
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

      def parse_csr(csr:, params: {})
        required_string!(:csr, csr)
        command = "namecheap.ssl.parseCSR"
        params = params.merge("csr" => csr)
        build_and_post(command, params)
      end

      def get_approver_email_list(domain_name:, certificate_type:, params: {})
        required_string!(:domain_name, domain_name)
        required_string!(:certificate_type, certificate_type)
        command = "namecheap.ssl.getApproverEmailList"
        params = params.merge("DomainName" => domain_name, "CertificateType" => certificate_type)
        build_and_get(command, params)
      end

      def activate(certificate_id:, csr:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        required_string!(:csr, csr)
        command = "namecheap.ssl.activate"
        params = params.merge("CertificateID" => certificate_id, "CSR" => csr)
        build_and_post(command, params)
      end

      def resend_approver_email(certificate_id:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        command = "namecheap.ssl.resendApproverEmail"
        params = params.merge("CertificateID" => certificate_id)
        build_and_post(command, params)
      end

      def get_info(certificate_id:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        command = "namecheap.ssl.getInfo"
        params = params.merge("CertificateID" => certificate_id)
        build_and_get(command, params)
      end

      def renew(certificate_id:, years:, certificate_type:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        positive_integer!(:years, years)
        required_string!(:certificate_type, certificate_type)
        command = "namecheap.ssl.renew"
        params = params.merge(
          "CertificateID" => certificate_id,
          "Years" => years,
          "SSLType" => certificate_type
        )
        build_and_post(command, params)
      end

      def reissue(certificate_id:, csr:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        required_string!(:csr, csr)
        command = "namecheap.ssl.reissue"
        params = params.merge("CertificateID" => certificate_id, "CSR" => csr)
        build_and_post(command, params)
      end

      def resend_fulfillment_email(certificate_id:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        command = "namecheap.ssl.resendfulfillmentemail"
        params = params.merge("CertificateID" => certificate_id)
        build_and_post(command, params)
      end

      def purchase_more_sans(certificate_id:, count:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        count = begin
          Integer(count)
        rescue TypeError, ArgumentError
          raise ArgumentError, "count must be an integer"
        end
        raise ArgumentError, "count must be between 1 and 99" unless (1..99).cover?(count)

        command = "namecheap.ssl.purchasemoresans"
        params = params.merge("CertificateID" => certificate_id, "NumberOfSANSToAdd" => count)
        build_and_post(command, params)
      end

      def revoke_certificate(certificate_id:, certificate_type:, params: {})
        positive_integer!(:certificate_id, certificate_id)
        required_string!(:certificate_type, certificate_type)
        command = "namecheap.ssl.revokecertificate"
        params = params.merge("CertificateID" => certificate_id, "CertificateType" => certificate_type)
        build_and_post(command, params)
      end

      def edit_dcv_method(certificate_id:, dcv_method: nil, domain_methods: nil, params: {})
        positive_integer!(:certificate_id, certificate_id)
        modes = [dcv_method, domain_methods].count { |value| !blank?(value) }
        raise ArgumentError, "provide exactly one of dcv_method or domain_methods" unless modes == 1

        command = "namecheap.ssl.editDCVMethod"
        params = params.merge("CertificateID" => certificate_id)
        if dcv_method
          required_string!(:dcv_method, dcv_method)
          params["DCVMethod"] = dcv_method
        else
          raise ArgumentError, "domain_methods must be a non-empty hash" unless domain_methods.is_a?(Hash) && domain_methods.any?

          domains = domain_methods.keys.map(&:to_s)
          methods = domain_methods.values.map(&:to_s)
          if domains.any?(&:empty?) || methods.any?(&:empty?)
            raise ArgumentError, "domain_methods cannot contain blank domains or methods"
          end
          params["DNSNames"] = domains.join(",")
          params["DCVMethods"] = methods.join(",")
        end
        build_and_post(command, params)
      end

      private

      def blank?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?) || value.to_s.empty?
      end
    end
  end
end
