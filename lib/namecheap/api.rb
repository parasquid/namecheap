module Namecheap
  class Api
    SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'
    PRODUCTION = 'https://api.namecheap.com/xml.response'
    ENVIRONMENT = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : (ENV["RACK_ENV"] || 'development')
    ENDPOINT = (ENVIRONMENT == 'production' ? PRODUCTION : SANDBOX)

    def get(command, options = {})
      request 'get', command, options
    end

    def post(command, options = {})
      request 'post', command, options
    end

    def put(command, options = {})
      request 'post', command, options
    end

    def delete(command, options = {})
      request 'post', command, options
    end

    def request(method, command, options = {})
      command = 'namecheap.' + command
      options = init_args.merge(options).merge({:command => command})
      options.camelize_keys!
      
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

    def init_args
      %w(username key client_ip).each do |key|
        if Namecheap.config.key.nil?
          raise Namecheap::Config::RequiredOptionMissing,
            "Configuration parameter missing: #{key}, " +
            "please add it to the Namecheap.configure block"
        end
      end
      options = {
        :ApiUser  => Namecheap.username,
        :UserName => Namecheap.username,
        :ApiKey   => Namecheap.key,
        :ClientIp => Namecheap.client_ip
      }
    end
  end
end
