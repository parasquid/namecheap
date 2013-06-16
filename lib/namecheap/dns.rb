module Namecheap
  class Dns < Api
    # Sets domain to use Namecheap's default DNS servers.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:setdefault
    def set_default(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get('domains.dns.setDefault', options)
    end

    # Sets domain to use custom DNS servers.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:setcustom
    def set_custom(sld, tld, nameservers = [], options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      options['Nameservers'] = nameservers.respond_to?(:join) ? nameservers.join(',') : nameservers
      get('domains.dns.setCustom', options)
    end

    # Gets a list of DNS servers associated with the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:getlist
    def get_list(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get('domains.dns.getList', options)
    end

    # Retrieves DNS host record settings for the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:gethosts
    def get_hosts(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get('domains.dns.getHosts', options)
    end

    # Gets email forwarding settings for the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:getemailforwarding
    def get_email_forwarding(domain, options = {})
      options['DomainName'] = domain
      get('domains.dns.getEmailForwarding', options)
    end

    # Sets email forwarding for a domain name.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:setemailforwarding
    def set_email_forwarding(domain, options = {})
      options['DomainName'] = domain
      get('domains.dns.setEmailForwarding', options)
    end

    # Sets DNS host records settings for the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.dns:sethosts
    def set_hosts(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get('domains.dns.setHosts', options)
    end
  end
end
