require_relative "lib/namecheap/version"

Gem::Specification.new do |spec|
  spec.name = "namecheap"
  spec.version = Namecheap::VERSION
  spec.authors = ["parasquid"]
  spec.email = ["tristan.gomez@gmail.com"]
  spec.summary = "Ruby wrapper for the Namecheap API"
  spec.description = "A small Ruby wrapper around Namecheap's XML API for managing domains, DNS, SSL certificates, transfers, users, and domain privacy."
  spec.homepage = "https://github.com/parasquid/namecheap"
  spec.license = "LGPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/parasquid/namecheap/issues",
    "changelog_uri" => "https://github.com/parasquid/namecheap/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/parasquid/namecheap",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb", "CHANGELOG.md", "COPYING", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.1", "< 9"
  spec.add_dependency "httparty", ">= 0.22", "< 1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "standard", "~> 1.55"
  spec.add_development_dependency "webmock", "~> 3.0"
end
