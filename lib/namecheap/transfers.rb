module Namecheap
  class Transfers < Api
    def create(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.transfer.create', options)
    end

    def get_status(id, options = {})
      options['TransferID'] = id
      api_call('namecheap.domains.transfer.getStatus', options)
    end

    def update_status(id, options = {})
      options['TransferID'] = id
      api_call('namecheap.domains.transfer.updateStatus', options)
    end
    
    def get_list(options = {})
      api_call('namecheap.domains.transfer.getList', options)
    end
  end
end
