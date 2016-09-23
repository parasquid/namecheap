# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "namecheap/version"

Gem::Specification.new do |s|
  s.name        = "namecheap"
  s.version     = Namecheap::VERSION
  s.authors     = ["parasquid"]
  s.email       = ["tristan.gomez@gmail.com"]
  s.homepage    = "https://github.com/parasquid/namecheap"
  s.description = %q{Ruby wrapper for the Namecheap API}
  s.summary     = s.description
  s.homepage    = 'https://github.com/parasquid/namecheap'
  s.licenses    = ['LGPLV3']

  s.rubyforge_project = "namecheap"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">= 3"
  s.add_development_dependency 'rspec-given'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard'
  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "addressable"
end
