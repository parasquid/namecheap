module Namecheap
  class Ns < Api
    def create(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.ns.create', args)
    end

    def delete(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.ns.delete', args)
    end

    def get_info(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.ns.getInfo', args)
    end

    def update(sld, tld, options = {})
      args = options.clone
      args['SLD'] = sld
      args['TLD'] = tld
      api_call('namecheap.domains.ns.update', args)
    end
  end
end
