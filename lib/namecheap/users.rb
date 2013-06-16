module Namecheap
  class Users < Api
    def create(options = {})
      api_call('namecheap.users.create', options)
    end

    def get_pricing(options = {})
      api_call('namecheap.users.getPricing', options)
    end

    def get_balances(options = {})
      api_call('namecheap.users.getBalances', options)
    end

    def change_password(options = {})
      api_call('namecheap.users.changePassword', options)
    end

    def update(options = {})
      api_call('namecheap.users.update', options)
    end

    def create_add_funds_request(options = {})
      api_call('namecheap.users.createaddfundsrequest', options)
    end

    def get_add_funds_status(id, options = {})
      options['TokenId'] = id
      api_call('namecheap.users.getAddFundsStatus', options)
    end

    def login(options = {})
      api_call('namecheap.users.login', options)
    end

    def reset_password(options = {})
      api_call('namecheap.users.resetPassword', options)
    end
  end
end
