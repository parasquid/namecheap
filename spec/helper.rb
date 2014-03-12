begin
  require 'rspec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift File.expand_path('../../lib',__FILE__)
require 'namecheap'
