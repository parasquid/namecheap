require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do
  require "pry"
  require 'namecheap'

  namecheap = Namecheap::API::Client.new(
    api_key: "56b4c87ef4fd49cb96d915c0db68194",
    api_user: "apiexample"
  )

  binding.pry
end