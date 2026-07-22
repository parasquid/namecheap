require "spec_helper"
require "tempfile"

RSpec.describe Namecheap do
  describe ".configure" do
    it "returns the configuration when called without a block" do
      expect(described_class.configure).to be(Namecheap::Config)
    end

    it "sets all supported options" do
      described_class.configure do |config|
        config.key = "the_apikey"
        config.username = "the_username"
        config.client_ip = "192.0.2.1"
      end

      expect(described_class.config.key).to eq("the_apikey")
      expect(described_class.config.username).to eq("the_username")
      expect(described_class.config.client_ip).to eq("192.0.2.1")
    end
  end

  describe Namecheap::Config do
    it "loads known options from a hash and ignores unknown options" do
      described_class.from_hash("username" => "user", "key" => "secret", "unknown" => "ignored")

      expect(described_class.username).to eq("user")
      expect(described_class.key).to eq("secret")
      expect(described_class).not_to respond_to(:unknown)
    end

    it "loads the current environment from an ERB-enabled YAML file" do
      file = Tempfile.new(["namecheap", ".yml"])
      file.write(<<~YAML)
        #{Namecheap::Api::ENVIRONMENT}:
          username: <%= "yaml_user" %>
          key: yaml_key
          client_ip: 192.0.2.2
      YAML
      file.close

      described_class.load!(file.path)

      expect(described_class.username).to eq("yaml_user")
      expect(described_class.key).to eq("yaml_key")
      expect(described_class.client_ip).to eq("192.0.2.2")
    ensure
      file&.unlink
    end
  end

  it "exposes initialized API resources" do
    expect(described_class.domains).to be_a(Namecheap::Domains)
    expect(described_class.dns).to be_a(Namecheap::Dns)
    expect(described_class.ns).to be_a(Namecheap::Ns)
    expect(described_class.transfers).to be_a(Namecheap::Transfers)
    expect(described_class.ssl).to be_a(Namecheap::Ssl)
    expect(described_class.users).to be_a(Namecheap::Users)
    expect(described_class.whois_guard).to be_a(Namecheap::Whois_Guard)
  end
end
