require "namecheap/api/base"

module Namecheap
  module API
    class Dns < Base
      def get_list(sld:, tld:)
        command = "namecheap.domains.dns.getList".freeze
        params = {
          "SLD" => sld,
          "TLD" => tld
        }
        build_and_get command, params
      end
    end
  end
end