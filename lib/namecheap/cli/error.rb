module Namecheap
  module CLI
    class Error < StandardError
      attr_reader :exit_code

      def initialize(message, exit_code: 2)
        @exit_code = exit_code
        super(message)
      end
    end
  end
end
