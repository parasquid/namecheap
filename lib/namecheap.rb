require 'httparty'

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/namecheap")
Dir.glob("#{File.dirname(__FILE__)}/namecheap/*.rb") { |lib| require File.basename(lib, '.*') }


module Namecheap
end


