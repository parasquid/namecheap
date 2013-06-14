module Namecheap
  class Users < Api
    def get_pricing(options = {})
      args = options.clone
      api_call('namecheap.users.getPricing', args)
    end

    def get_balances(options = {})
      args = options.clone
      api_call('namecheap.users.getBalances', args)
    end

    def change_password(options = {})
      args = options.clone
      api_call('namecheap.users.changePassword', args)
    end

    def update(options = {})
      args = options.clone
      api_call('namecheap.users.update', args)
    end

    def create_add_funds_request(options = {})
      args = options.clone
      api_call('namecheap.users.createaddfundsrequest', args)
    end

    def get_add_funds_status(id, options = {})
      args = options.clone
      args['TokenId'] = id
      api_call('namecheap.users.getAddFundsStatus', args)
    end

    def login(options = {})
      args = options.clone
      api_call('namecheap.users.login', args)
    end

    def reset_password(options = {})
      args = options.clone
      api_call('namecheap.users.resetPassword', args)
    end
  end
end
