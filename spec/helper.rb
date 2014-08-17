begin
  require 'rspec'
  require 'rspec/its'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift File.expand_path('../../lib',__FILE__)
require 'namecheap'

RSpec.configure do |config|
  def reset_config
    Namecheap.config.username = nil
    Namecheap.config.key = nil
    Namecheap.config.client_ip = nil
  end

  def set_dummy_config
    Namecheap.config.username = "the_username"
    Namecheap.config.key = "the_key"
    Namecheap.config.client_ip = "127.0.0.1"
  end
end
