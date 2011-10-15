module Namecheap
  class Domains < Api
    def get_list(options = {})
      args = options.clone
      api_call('namecheap.domains.getList', args)
    end

    def check(domains = [], options = {})
      args = options.clone
      args['DomainList'] = domains.respond_to?(:join) ? domains.join(',') : domains
      api_call('namecheap.domains.check', args)
    end
  end
end