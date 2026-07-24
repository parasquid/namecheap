require "namecheap/api/base"

module Namecheap
  module API
    class Users < Base
      # https://www.namecheap.com/support/api/methods/users/get-pricing/
      def get_pricing(product_type:, params: {})
        command = "namecheap.users.getPricing"
        params = params.merge("ProductType" => product_type)
        build_and_get(command, params)
      end
    end
  end
end
