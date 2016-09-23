require "namecheap/api/base"

module Namecheap
  module API
    class Dns < Base
      def get_list(sld:, tld:)
        command = "namecheap.domains.dns.getList"
      end
    end
  end
end