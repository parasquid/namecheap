require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do
  require "pry"
  require "namecheap"
  require "dotenv"
  Dotenv.load

  namecheap = Namecheap::API::Client.new(
    api_key: ENV["APIKEY"],
    api_user: ENV["APIUSER"],
    environment: ENV["ENVIRONMENT"]
  )

  binding.pry
end
