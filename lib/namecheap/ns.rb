module Namecheap
  class Ns < Api
    # Creates a new nameserver.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.ns:create
    def create(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get 'domains.ns.create', options
    end

    # Deletes a nameserver associated with the requested domain.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.ns:delete
    def delete(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get 'domains.ns.delete', options
    end

    # Retrieves information about a registered nameserver.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.ns:getinfo
    def get_info(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get 'domains.ns.getInfo', options
    end

    # Updates the IP address of a registered nameserver.
    # @see http://developer.namecheap.com/docs/doku.php?id=api-reference:domains.ns:update
    def update(sld, tld, options = {})
      options['SLD'] = sld
      options['TLD'] = tld
      get 'domains.ns.update', options
    end
  end
end
