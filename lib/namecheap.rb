require 'monkey_patch'
require 'httparty'

module Namecheap
  SANDBOX = 'https://api.sandbox.namecheap.com/xml.response'
  PRODUCTION = 'https://api.namecheap.com/xml.response'
  class Namecheap
    attr_reader :username, :key, :client_ip
    def initialize(options = {})
      config_file = options[:config_file] || "#{File.dirname(__FILE__)}/../config/namecheap.yml"
      environment = options[:environment] || ENV['RACK_ENV'] || 'development'
      config = options[:config_file] || YAML.load_file(config_file)[environment].symbolize_keys!
      @key = options[:key] || config[:key]
      @username = options[:username] || config[:username]
      @client_ip = options[:client_ip] || config[:client_ip]
    end

    protected

    def api_call
      
    end
  end
end
