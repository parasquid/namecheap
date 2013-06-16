module Namecheap
  class Users < Api
    # Creates a new user account at NameCheap.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:create
    def create(options = {})
      api_call('users.create', options)
    end

    # Returns pricing information for a requested product type.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:getpricing
    def get_pricing(options = {})
      api_call('users.getPricing', options)
    end

    # Gets information about fund in the user's account.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:getbalances
    def get_balances(options = {})
      api_call('users.getBalances', options)
    end

    # Changes the password for a user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:changepassword
    def change_password(options = {})
      api_call('users.changePassword', options)
    end

    # Updates user account information for the particular user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:update
    def update(options = {})
      api_call('users.update', options)
    end

    # Allows you to add funds to a user account.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:createaddfundsrequest
    def create_add_funds_request(options = {})
      api_call('users.createaddfundsrequest', options)
    end

    # Gets the status of add funds request.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:getaddfundsstatus
    def get_add_funds_status(id, options = {})
      options['TokenId'] = id
      api_call('users.getAddFundsStatus', options)
    end

    # Validates the username and password of user accounts you have created.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:login
    def login(options = {})
      api_call('users.login', options)
    end

    # Sends a reset password link to user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:resetpassword
    def reset_password(options = {})
      api_call('users.resetPassword', options)
    end
  end
end
