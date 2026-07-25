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
        config.environment = "sandbox"
      end

      expect(described_class.config.key).to eq("the_apikey")
      expect(described_class.config.username).to eq("the_username")
      expect(described_class.config.client_ip).to eq("192.0.2.1")
      expect(described_class.config.environment).to eq("sandbox")
    end
  end

  describe Namecheap::Config do
    it "loads known options from a hash and ignores unknown options" do
      described_class.from_hash(
        "username" => "user",
        "key" => "secret",
        "environment" => "production",
        "unknown" => "ignored"
      )

      expect(described_class.username).to eq("user")
      expect(described_class.key).to eq("secret")
      expect(described_class.environment).to eq("production")
      expect(described_class).not_to respond_to(:unknown)
    end

    ["staging", :sandbox, ""].each do |environment|
      it "rejects unsupported Namecheap environment #{environment.inspect}" do
        expect { described_class.environment = environment }
          .to raise_error(ArgumentError, "environment must be sandbox or production")
      end
    end

    it "uses nil to restore automatic environment selection" do
      described_class.environment = "production"

      expect { described_class.environment = nil }
        .to change(described_class, :environment).from("production").to(nil)
    end

    it "loads the current environment from an ERB-enabled YAML file" do
      file = Tempfile.new(["namecheap", ".yml"])
      file.write(<<~YAML)
        #{Namecheap::Api::ENVIRONMENT}:
          username: <%= "yaml_user" %>
          key: yaml_key
          client_ip: 192.0.2.2
          environment: sandbox
      YAML
      file.close

      described_class.load!(file.path)

      expect(described_class.username).to eq("yaml_user")
      expect(described_class.key).to eq("yaml_key")
      expect(described_class.client_ip).to eq("192.0.2.2")
      expect(described_class.environment).to eq("sandbox")
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
