require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do
  require "pry"
  require 'namecheap'

  namecheap = Namecheap::API::Client.new(api_key: "x", api_user: "y")

  binding.pry
end