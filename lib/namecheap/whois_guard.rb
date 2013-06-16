module Namecheap
  class Whois_Guard < Api
    def allot(id, domain, options = {})
      options['WhoisguardId'] = id
      options['DomainName'] = domain
      api_call('namecheap.whoisguard.allot', options)
    end

    def discard(id, options = {})
      options['WhoisguardId'] = id
      api_call('namecheap.whoisguard.discard', options)
    end

    def unallot(id, options = {})
      options['WhoisguardId'] = id
      api_call('namecheap.whoisguard.unallot', options)
    end

    def disable(id, options = {})
      options['WhoisguardId'] = id
      api_call('namecheap.whoisguard.disable', options)
    end

    def enable(id, options = {})
      options['WhoisguardId'] = id
      api_call('namecheap.whoisguard.enable', options)
    end

    def change_email_address(id, options = {})
      options['WhoisguardId'] = id
      api_call('namecheap.whoisguard.changeemailaddress', options)
    end
  end
end
