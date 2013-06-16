begin
  require 'rspec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

require File.dirname(__FILE__) + '/../lib/namecheap'
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib/namecheap")
