module Namecheap
  class Transfers < Api
    def create(domain, options = {})
      args = options.clone
      args['DomainName'] = domain
      api_call('namecheap.domains.transfer.create', args)
    end

    def get_status(id, options = {})
      args = options.clone
      args['TransferID'] = id
      api_call('namecheap.domains.transfer.getStatus', args)
    end

    def update_status(id, options = {})
      args = options.clone
      args['TransferID'] = id
      api_call('namecheap.domains.transfer.updateStatus', args)
    end
    
    def get_list(options = {})
      args = options.clone
      api_call('namecheap.domains.transfer.getList', args)
    end
  end
end
