module Namecheap
  class Api
    SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'
    PRODUCTION = 'https://api.namecheap.com/xml.response'
    ENVIRONMENT = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : (ENV["RACK_ENV"] || 'development')
    ENDPOINT = (ENVIRONMENT == 'production' ? PRODUCTION : SANDBOX)

    def api_call(command, command_args)
      args = init_args(command_args.merge :command => command)
      query = ENDPOINT + '?' + args.to_param
      HTTParty.get(query)
    end

    def init_args(options = {})
      args = {}
      args['ApiUser'] = args['UserName'] = Namecheap.username
      args['ApiKey'] = Namecheap.key
      args['ClientIp'] = Namecheap.client_ip
      args.merge options.camelize_keys!
    end
  end
end