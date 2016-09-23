require "namecheap/api/base"

module Namecheap
  module API
    class Dns < Base
      def get_list(sld:, tld:)
        command = "namecheap.domains.dns.getList".freeze
        url = endpoint(command, params: {
            "SLD" => sld,
            "TLD" => tld
          }
        )
        execute url
      end
    end
  end
end