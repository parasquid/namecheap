module Namecheap
  class Ssl < Api
    def activate(id, options = {})
      args = options.clone
      args['CertificateID'] = id
      api_call('namecheap.ssl.activate', args)
    end

    def get_info(id, options = {})
      args = options.clone
      args['CertificateID'] = id
      api_call('namecheap.ssl.getInfo', args)
    end

    def parse_csr(csr, options = {})
      args = options.clone
      args['csr'] = csr
      api_call('namecheap.ssl.parseCSR', args)
    end

    def get_approver_email_list(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.ssl.getApproverEmailList', args)
    end

    def get_list(options = {})
      args = options.clone
      api_call('namecheap.ssl.getList', args)
    end

    def create(options = {})
      args = options.clone
      api_call('namecheap.ssl.create', args)
    end

    def renew(options = {})
      args = options.clone
      api_call('namecheap.ssl.renew', args)
    end

    def resend_approver_email(id, options = {})
      args = options.clone
      args['CertificateID'] = id
      api_call('namecheap.ssl.resendApproverEmail', args)
    end

    def resend_fulfillment_email(id, options = {})
      args = options.clone
      args['CertificateID'] = id
      api_call('namecheap.ssl.resendfulfillmentemail', args)
    end

    def reissue(id, options = {})
      args = options.clone
      args['CertificateID'] = id
      api_call('namecheap.ssl.reissue', args)
    end
  end
end
