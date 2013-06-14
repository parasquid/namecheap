module Namecheap
  class Domains < Api
    def get_list(options = {})
      args = options.clone
      api_call('namecheap.domains.getList', args)
    end

    def get_contacts(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.getContacts', args)
    end

    def create(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.create', args)
    end

    def get_tld_list(options = {})
      args = options.clone
      api_call('namecheap.domains.getTldList', args)
    end

    def set_contacts(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.setContacts', args)
    end

    def check(domains = [], options = {})
      args = options.clone
      args['DomainList'] = domains.respond_to?(:join) ? domains.join(',') : domains
      api_call('namecheap.domains.check', args)
    end

    def reactivate(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.reactivate', args)
    end

    def renew(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.renew', args)
    end

    def get_registrar_lock(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.getRegistrarLock', args)
    end

    def set_registrar_lock(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.setRegistrarLock', args)
    end

    def get_info(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.getInfo', args)
    end
  end
end
