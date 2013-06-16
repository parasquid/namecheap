module Namecheap
  class Domains < Api
    # Returns a list of domains for the particular user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:getlist
    def get_list(options = {})
      api_call('namecheap.domains.getList', options)
    end

    # Gets contact information for the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:getcontacts
    def get_contacts(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.getContacts', options)
    end

    # Registers a domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:create
    def create(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.create', options)
    end

    # Returns a list of tlds.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:gettldlist
    def get_tld_list(options = {})
      api_call('namecheap.domains.getTldList', options)
    end

    # Sets contact information for the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:setcontacts
    def set_contacts(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.setContacts', options)
    end

    # Checks the availability of domains.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:check
    def check(domains = [], options = {})
      options['DomainList'] = domains.respond_to?(:join) ? domains.join(',') : domains
      api_call('namecheap.domains.check', options)
    end

    # Reactivates an expired domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:reactivate
    def reactivate(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.reactivate', options)
    end

    # Renews an expiring domain.
    # http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:renew
    def renew(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.renew', options)
    end

    # Gets the status of RegistrarLock for the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:getregistrarlock
    def get_registrar_lock(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.getRegistrarLock', options)
    end

    # Sets the RegistrarLock status for a domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:setregistrarlock
    def set_registrar_lock(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.setRegistrarLock', options)
    end

    # Returns information about the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains:getinfo
    def get_info(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.getInfo', options)
    end
  end
end
