require 'httparty'

module Namecheap
  SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'
  PRODUCTION = 'https://api.namecheap.com/xml.response'
  class Api
    attr_reader :username, :key, :client_ip
    def initialize(options = {})
      config_file = options[:config_file] || "#{File.dirname(__FILE__)}/../config/namecheap.yml"
      environment = options[:environment] || ENV['RACK_ENV'] || 'development'
      config = options[:config_file] || YAML.load_file(config_file)[environment].symbolize_keys!
      @key = options[:key] || config[:key]
      @username = options[:username] || config[:username]
      @client_ip = options[:client_ip] || config[:client_ip]
      @endpoint = (environment == 'production' ? PRODUCTION : SANDBOX)
    end

    protected

    def api_call(command, command_args)
      args = {}
      args['ApiUser'] = args['UserName'] = @username
      args['ApiKey'] = @key
      args['ClientIp'] = @client_ip
      args['Command'] = command
      query = @endpoint + '?' + args.to_param
      HTTParty.get(query)
    end
  end
end

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/namecheap")
Dir.glob("#{File.dirname(__FILE__)}/namecheap/*.rb") { |lib| require File.basename(lib, '.*') }
