require "fileutils"
require "yaml"

module Namecheap
  module CLI
    class ConfigStore
      attr_reader :path

      def initialize(path)
        @path = File.expand_path(path)
      end

      def data
        @data ||= begin
          value = File.exist?(path) ? YAML.safe_load_file(path, permitted_classes: [], aliases: false) : {}
          raise Error, "config must contain a mapping: #{path}" unless value.is_a?(Hash)

          {"version" => 1, "profiles" => {}, "contacts" => {}}.merge(value)
        rescue Psych::Exception
          raise Error, "invalid config at #{path}: expected valid YAML"
        end
      end

      def save!
        directory = File.dirname(path)
        FileUtils.mkdir_p(directory, mode: 0o700)
        File.chmod(0o700, directory)
        temporary = "#{path}.tmp.#{$$}"
        File.open(temporary, File::WRONLY | File::CREAT | File::TRUNC, 0o600) { |file| file.write(YAML.dump(data)) }
        File.chmod(0o600, temporary)
        File.rename(temporary, path)
      ensure
        File.delete(temporary) if defined?(temporary) && File.exist?(temporary)
      end

      def profiles
        data["profiles"] ||= {}
      end

      def contacts
        data["contacts"] ||= {}
      end
    end
  end
end
