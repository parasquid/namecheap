module Namecheap
  module CLI
    module EnvFile
      def self.load(path)
        File.readlines(path, chomp: true).each_with_object({}) do |line, values|
          line = line.strip
          next if line.empty? || line.start_with?("#")

          key, value = line.sub(/\Aexport\s+/, "").split("=", 2)
          raise Error, "invalid env-file line: #{line}" unless key&.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/) && value

          values[key] = unquote(value.strip)
        end
      rescue Errno::ENOENT
        raise Error, "env file not found: #{path}"
      end

      def self.unquote(value)
        return value[1...-1] if value.length >= 2 && ["'", "\""].include?(value[0]) && value[-1] == value[0]

        value
      end
    end
  end
end
