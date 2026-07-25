require "namecheap/api/base"

module Namecheap
  module API
    class Nameservers < Base
      def create(sld:, tld:, nameserver:, ip:, params: {})
        command = "namecheap.domains.ns.create"
        params = params.merge("SLD" => sld, "TLD" => tld, "Nameserver" => nameserver, "IP" => ip)
        build_and_post(command, params)
      end

      def delete(sld:, tld:, nameserver:, params: {})
        command = "namecheap.domains.ns.delete"
        params = params.merge("SLD" => sld, "TLD" => tld, "Nameserver" => nameserver)
        build_and_post(command, params)
      end

      def get_info(sld:, tld:, nameserver:, params: {})
        command = "namecheap.domains.ns.getInfo"
        params = params.merge("SLD" => sld, "TLD" => tld, "Nameserver" => nameserver)
        build_and_get(command, params)
      end

      def update(sld:, tld:, nameserver:, old_ip:, ip:, params: {})
        command = "namecheap.domains.ns.update"
        params = params.merge(
          "SLD" => sld,
          "TLD" => tld,
          "Nameserver" => nameserver,
          "OldIP" => old_ip,
          "IP" => ip
        )
        build_and_post(command, params)
      end
    end
  end
end
