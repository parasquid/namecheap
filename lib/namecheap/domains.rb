module Namecheap
  class Domains < Api
    def get_list(options = {})
      api_call('namecheap.domains.getList', options)
    end

    def get_contacts(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.getContacts', options)
    end

    def create(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.create', options)
    end

    def get_tld_list(options = {})
      api_call('namecheap.domains.getTldList', options)
    end

    def set_contacts(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.setContacts', options)
    end

    def check(domains = [], options = {})
      options['DomainList'] = domains.respond_to?(:join) ? domains.join(',') : domains
      api_call('namecheap.domains.check', options)
    end

    def reactivate(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.reactivate', options)
    end

    def renew(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.renew', options)
    end

    def get_registrar_lock(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.getRegistrarLock', options)
    end

    def set_registrar_lock(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.setRegistrarLock', options)
    end

    def get_info(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.getInfo', options)
    end
  end
end
