require_relative "lib/namecheap/version"

Gem::Specification.new do |spec|
  spec.name = "namecheap"
  spec.version = Namecheap::VERSION
  spec.authors = ["parasquid"]
  spec.email = ["tristan.gomez@gmail.com"]
  spec.summary = "Ruby wrapper for the Namecheap API"
  spec.description = "An experimental instance-based Ruby client for Namecheap's XML API."
  spec.homepage = "https://github.com/parasquid/namecheap"
  spec.license = "LGPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/parasquid/namecheap/issues",
    "changelog_uri" => "https://github.com/parasquid/namecheap/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/parasquid/namecheap",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["exe/namecheap", "lib/namecheap.rb", "lib/namecheap/version.rb", "lib/namecheap/api/**/*.rb", "lib/namecheap/cli/**/*.rb", "lib/namecheap/cli.rb", "CHANGELOG.md", "COPYING", "README.md"]
  end
  spec.bindir = "exe"
  spec.executables = ["namecheap"]
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable", ">= 2.8", "< 3"
  spec.add_dependency "faraday", ">= 2.9", "< 3"
  spec.add_dependency "rexml", ">= 3.4", "< 4"
  spec.add_dependency "thor", ">= 1.5", "< 2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "standard", "~> 1.55"
  spec.add_development_dependency "webmock", "~> 3.0"
end
