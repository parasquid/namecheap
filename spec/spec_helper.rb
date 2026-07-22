require "namecheap"
require "webmock/rspec"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.before do
    WebMock.disable_net_connect!
  end
end
