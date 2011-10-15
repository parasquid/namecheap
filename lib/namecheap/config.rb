module Namecheap
  module Config
    # Taken and modified from Mongoid config.rb

    extend self

    attr_accessor :settings, :defaults
    @settings = {}
    @defaults = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    #   Config.option(:client_ip, :default => '127.0.0.1')
    #
    # @param [ Symbol ] name The name of the configuration option.
    # @param [ Hash ] options Extras for the option.
    #
    # @option options [ Object ] :default The default value.
    def option(name, options = {})
      defaults[name] = settings[name] = options[:default]

      class_eval <<-RUBY
        def #{name}
          settings[#{name.inspect}]
        end

        def #{name}=(value)
          settings[#{name.inspect}] = value
        end

        def #{name}?
          #{name}
        end
      RUBY
    end

    option :key, :default => 'apikey'
    option :username, :default => 'apiuser'
    option :client_ip, :default => '127.0.0.1'

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

    # Reset the configuration options to the defaults.
    #
    # @example Reset the configuration options.
    #   config.reset
    def reset
      settings.replace(defaults)
    end

  end
end