require 'httparty'
require 'monkey_patch'
require 'pp'

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/namecheap")
Dir.glob("#{File.dirname(__FILE__)}/namecheap/*.rb") { |lib| require File.basename(lib, '.*') }

module Namecheap

  extend self

  # Sets the Mongoid configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   Namecheap.configure do |config|
  #     key = "apikey"
  #     username = "apiuser"
  #     client_ip = "127.0.0.1"
  #   end
  # @return [ Config ] The configuration obejct.
  def configure
    block_given? ? yield(Config) : Config
  end
  alias :config :configure
  
  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Namecheap module directly.
  #
  # @example Delegate the configuration methods.
  #   Namecheap.key = 'newkey'
  delegate *(Config.public_instance_methods(false) << { :to => Config })

  attr_accessor :domains
  self.domains = Namecheap::Domains.new

end
