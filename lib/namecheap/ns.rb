module Namecheap
  class Ns < Api
    def create(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.ns.create', options)
    end

    def delete(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.ns.delete', options)
    end

    def get_info(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.ns.getInfo', options)
    end

    def update(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      api_call('namecheap.domains.ns.update', options)
    end
  end
end
