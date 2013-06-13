module Namecheap
  class Dns < Api
    def set_default(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.dns.setDefault', args)
    end

    def set_custom(sld, tld, nameservers = [], options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      args['Nameservers'] = nameservers.respond_to?(:join) ? nameservers.join(',') : nameservers
      api_call('namecheap.domains.dns.setCustom', args)
    end

    def get_list(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.dns.getList', args)
    end

    def get_hosts(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.dns.getHosts', args)
    end

    def get_email_forwarding(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.dns.getEmailForwarding', args)
    end

    def set_email_forwarding(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.dns.setEmailForwarding', args)
    end

    def set_hosts(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.dns.setHosts', args)
    end
  end
end
