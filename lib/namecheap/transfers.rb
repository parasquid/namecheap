module Namecheap
  class Transfers < Api
    # Transfers a domain to Namecheap.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.transfer:create
    def create(domain, options = {})
      options['DomainName'] = domain
      api_call('namecheap.domains.transfer.create', options)
    end

    # Gets the status of a particular transfer.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.transfer:getstatus
    def get_status(id, options = {})
      options['TransferID'] = id
      api_call('namecheap.domains.transfer.getStatus', options)
    end

    # Updates the status of a particular transfer.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.transfer:updatestatus
    def update_status(id, options = {})
      options['TransferID'] = id
      api_call('namecheap.domains.transfer.updateStatus', options)
    end

    # Gets the list of domain transfers.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.transfer:getlist
    def get_list(options = {})
      api_call('namecheap.domains.transfer.getList', options)
    end
  end
end
