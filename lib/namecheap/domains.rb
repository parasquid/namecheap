module Namecheap
  class Domains < Namecheap::Api
    def get_list(options = {})
      args = options.clone
      api_call('namecheap.domains.getList', args)
    end
  end
end
