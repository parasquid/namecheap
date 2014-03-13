module Namecheap
  module Config
    class RequiredOptionMissing < RuntimeError ; end
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
      settings = YAML.load(ERB.new(File.new(path).read).result)[ENVIRONMENT]
      if settings.present?
        from_hash(settings)
      end
    end
  end
end
