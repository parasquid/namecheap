module Namecheap
  class Ssl < Api
    def activate(id, options = {})
      options['CertificateID'] = id
      api_call('namecheap.ssl.activate', options)
    end

    def get_info(id, options = {})
      options['CertificateID'] = id
      api_call('namecheap.ssl.getInfo', options)
    end

    def parse_csr(csr, options = {})
      options['csr'] = csr
      api_call('namecheap.ssl.parseCSR', options)
    end

    def get_approver_email_list(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.ssl.getApproverEmailList', options)
    end

    def get_list(options = {})
      api_call('namecheap.ssl.getList', options)
    end

    def create(options = {})
      api_call('namecheap.ssl.create', options)
    end

    def renew(options = {})
      api_call('namecheap.ssl.renew', options)
    end

    def resend_approver_email(id, options = {})
      options['CertificateID'] = id
      api_call('namecheap.ssl.resendApproverEmail', options)
    end

    def resend_fulfillment_email(id, options = {})
      options['CertificateID'] = id
      api_call('namecheap.ssl.resendfulfillmentemail', options)
    end

    def reissue(id, options = {})
      options['CertificateID'] = id
      api_call('namecheap.ssl.reissue', options)
    end
  end
end
