require "namecheap/cli/runner"

module Namecheap
  module CLI
    def self.run(argv, stdout: $stdout, stderr: $stderr, stdin: $stdin, env: ENV)
      Runner.new(stdout: stdout, stderr: stderr, stdin: stdin, env: env).run(argv)
    end
  end
end
