require "namecheap/api/base"

module Namecheap
  module API
    class Ssl < Base
      def create(years:, certificate_type:, params: {})
        command = "namecheap.ssl.create"
        params = params.merge("Years" => years, "Type" => certificate_type)
        build_and_post(command, params)
      end

      def get_list(params: {})
        command = "namecheap.ssl.getList"
        build_and_get(command, params)
      end

      def parse_csr(csr:, params: {})
        command = "namecheap.ssl.parseCSR"
        params = params.merge("csr" => csr)
        build_and_post(command, params)
      end

      def get_approver_email_list(domain_name:, certificate_type:, params: {})
        command = "namecheap.ssl.getApproverEmailList"
        params = params.merge("DomainName" => domain_name, "CertificateType" => certificate_type)
        build_and_get(command, params)
      end

      def activate(certificate_id:, csr:, params: {})
        command = "namecheap.ssl.activate"
        params = params.merge("CertificateID" => certificate_id, "CSR" => csr)
        build_and_post(command, params)
      end

      def resend_approver_email(certificate_id:, params: {})
        command = "namecheap.ssl.resendApproverEmail"
        params = params.merge("CertificateID" => certificate_id)
        build_and_post(command, params)
      end

      def get_info(certificate_id:, params: {})
        command = "namecheap.ssl.getInfo"
        params = params.merge("CertificateID" => certificate_id)
        build_and_get(command, params)
      end

      def renew(certificate_id:, years:, certificate_type:, params: {})
        command = "namecheap.ssl.renew"
        params = params.merge(
          "CertificateID" => certificate_id,
          "Years" => years,
          "SSLType" => certificate_type
        )
        build_and_post(command, params)
      end

      def reissue(certificate_id:, csr:, params: {})
        command = "namecheap.ssl.reissue"
        params = params.merge("CertificateID" => certificate_id, "CSR" => csr)
        build_and_post(command, params)
      end

      def resend_fulfillment_email(certificate_id:, params: {})
        command = "namecheap.ssl.resendfulfillmentemail"
        params = params.merge("CertificateID" => certificate_id)
        build_and_post(command, params)
      end
    end
  end
end
