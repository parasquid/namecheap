module Namecheap
  class Api
    SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'
    PRODUCTION = 'https://api.namecheap.com/xml.response'
    ENVIRONMENT = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : (ENV["RACK_ENV"] || 'development')
    ENDPOINT = (ENVIRONMENT == 'production' ? PRODUCTION : SANDBOX)

    def get(command, options = {})
      request('get', command, options)
    end

    def post(command, options = {})
      request('post', command, options)
    end

    def put(command, options = {})
      request('post', command, options)
    end

    def delete(command, options = {})
      request('post', command, options)
    end

    def request(method, command, options = {})
      options = init_args(options.merge :command => 'namecheap.' + command)
      
      case method
      when 'get'
        HTTParty.get(ENDPOINT, options)
      when 'post'
        HTTParty.post(ENDPOINT, options)
      when 'put'
        HTTParty.put(ENDPOINT, options)
      when 'delete'
        HTTParty.delete(ENDPOINT, options)
      end
    end

    def init_args(options = {})
      options['ApiUser'] = options['UserName'] = Namecheap.username
      options['ApiKey'] = Namecheap.key
      options['ClientIp'] = Namecheap.client_ip
      options.camelize_keys!
    end
  end
end
