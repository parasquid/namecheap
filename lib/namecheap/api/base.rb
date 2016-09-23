module Namecheap
  module API
    class Base
      def initialize(config)
        @config = config
        @api_user = config[:api_user]
        @api_key = config[:api_key]
        @user_name = config[:user_name]
        @client_ip = config[:client_ip]
      end
    end
  end
end