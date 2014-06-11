require 'httparty'
require 'pp'
require 'namecheap/version'
require 'namecheap/api'
require 'namecheap/config'
require 'namecheap/domains'
require 'namecheap/dns'
require 'namecheap/ns'
require 'namecheap/ssl'
require 'namecheap/transfers'
require 'namecheap/users'
require 'namecheap/whois_guard'

module Namecheap

  extend self

  # Sets the Namecheap configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   Namecheap.configure do |config|
  #     config.key = "apikey"
  #     config.username = "apiuser"
  #     config.client_ip = "127.0.0.1"
  #   end
  # @return [ Config ] The configuration obejct.
  def configure
    block_given? ? yield(Config) : Config
  end
  alias :config :configure

  attr_accessor :domains, :dns, :ns, :transfers, :ssl, :users, :whois_guard
  self.domains = Namecheap::Domains.new
  self.dns = Namecheap::Dns.new
  self.ns = Namecheap::Ns.new
  self.transfers = Namecheap::Transfers.new
  self.ssl = Namecheap::Ssl.new
  self.users = Namecheap::Users.new
  self.whois_guard = Namecheap::Whois_Guard.new

end
