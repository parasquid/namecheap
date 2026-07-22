require "erb"
require "yaml"

module Namecheap
  module Config
    class RequiredOptionMissing < RuntimeError; end
    extend self

    attr_accessor :key, :username, :client_ip

    # Configure namecheap from a hash. This is usually called after parsing a
    # yaml config file such as mongoid.yml.
    #
    # @example Configure Namecheap.
    #   config.from_hash({})
    #
    # @param [ Hash ] options The settings to use.
    def from_hash(options = {})
      options.each_pair do |name, value|
        send("#{name}=", value) if respond_to?("#{name}=")
      end
    end

    # Load the settings from a compliant namecheap.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Namecheap.
    #   Namecheap.load!("/path/to/namecheap.yml")
    #
    # @param [ String ] path The path to the file.
    def load!(path)
      contents = ERB.new(File.read(path)).result
      settings = YAML.safe_load(contents, aliases: true)&.fetch(Namecheap::Api::ENVIRONMENT, nil)
      from_hash(settings) if settings && !settings.empty?
    end
  end
end
