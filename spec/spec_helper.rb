require "namecheap"
require "webmock/rspec"

module ConfigHelpers
  def reset_config
    Namecheap.config.username = nil
    Namecheap.config.key = nil
    Namecheap.config.client_ip = nil
  end

  def set_dummy_config
    Namecheap.config.username = "the_username"
    Namecheap.config.key = "the_key"
    Namecheap.config.client_ip = "127.0.0.1"
  end
end

RSpec.configure do |config|
  config.include ConfigHelpers
  config.disable_monkey_patching!
  config.order = :random
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.before do
    WebMock.disable_net_connect!
  end

  config.after do
    reset_config
  end
end
