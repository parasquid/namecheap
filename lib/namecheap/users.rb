module Namecheap
  class Users < Api
    # Creates a new user account at NameCheap.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:create
    def create(options = {})
      get 'users.create', options
    end

    # Returns pricing information for a requested product type.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:getpricing
    def get_pricing(options = {})
      get 'users.getPricing', options
    end

    # Gets information about fund in the user's account.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:getbalances
    def get_balances(options = {})
      get 'users.getBalances', options
    end

    # Changes the password for a user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:changepassword
    def change_password(options = {})
      get 'users.changePassword', options
    end

    # Updates user account information for the particular user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:update
    def update(options = {})
      get 'users.update', options
    end

    # Allows you to add funds to a user account.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:createaddfundsrequest
    def create_add_funds_request(options = {})
      get 'users.createaddfundsrequest', options
    end

    # Gets the status of add funds request.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:getaddfundsstatus
    def get_add_funds_status(id, options = {})
      options = {:TokenId => id}.merge(options)
      get 'users.getAddFundsStatus', options
    end

    # Validates the username and password of user accounts you have created.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:login
    def login(options = {})
      get 'users.login', options
    end

    # Sends a reset password link to user.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:users:resetpassword
    def reset_password(options = {})
      get 'users.resetPassword', options
    end
  end
end
