require "namecheap/api/base"

module Namecheap
  module API
    class Dns < Base
      COMMAND = "namecheap.domains.dns.getList"

      def get_list(sld:, tld:)
      end
    end
  end
end