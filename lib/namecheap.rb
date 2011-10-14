require 'monkey_patch'
require 'httparty'

module Namecheap
  class Namecheap
    attr_reader :username, :key, :client_ip
    def initialize(options = {})
      config = YAML.load_file("#{File.dirname(__FILE__)}/../config/namecheap.yml").symbolize_keys!
      @key = options[:key] || config[:key]
      @username = options[:username] || config[:username]
      @client_ip = options[:client_ip] || config[:client_ip]
    end
  end
end
