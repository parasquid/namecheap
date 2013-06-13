module Namecheap
  class Whois_Guard < Api
    def allot(id, domain, options = {})
      args = options.clone
      args['WhoisguardId'] = id
      args['DomainName'] = domain
      api_call('namecheap.whoisguard.allot', args)
    end

    def discard(id, options = {})
      args = options.clone
      args['WhoisguardId'] = id
      api_call('namecheap.whoisguard.discard', args)
    end

    def unallot(id, options = {})
      args = options.clone
      args['WhoisguardId'] = id
      api_call('namecheap.whoisguard.unallot', args)
    end

    def disable(id, options = {})
      args = options.clone
      args['WhoisguardId'] = id
      api_call('namecheap.whoisguard.disable', args)
    end

    def enable(id, options = {})
      args = options.clone
      args['WhoisguardId'] = id
      api_call('namecheap.whoisguard.enable', args)
    end

    def change_email_address(id, options = {})
      args = options.clone
      args['WhoisguardId'] = id
      api_call('namecheap.whoisguard.changeemailaddress', args)
    end
  end
end
