module Namecheap
  class Dns < Api
    def set_default(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.dns.setDefault', options)
    end

    def set_custom(sld, tld, nameservers = [], options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      options['Nameservers'] = nameservers.respond_to?(:join) ? nameservers.join(',') : nameservers
      api_call('namecheap.domains.dns.setCustom', options)
    end

    def get_list(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.dns.getList', options)
    end

    def get_hosts(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.dns.getHosts', options)
    end

    def get_email_forwarding(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.dns.getEmailForwarding', options)
    end

    def set_email_forwarding(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.dns.setEmailForwarding', options)
    end

    def set_hosts(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.dns.setHosts', options)
    end
  end
end
