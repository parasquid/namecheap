require "spec_helper"

RSpec.describe Namecheap::API::Client do
  subject(:client) do
    described_class.new(
      api_user: "api-user",
      api_key: "api-key",
      client_ip: "192.0.2.1"
    )
  end

  it "builds isolated configuration with safe defaults" do
    other = described_class.new(api_user: "other", api_key: "secret", client_ip: "192.0.2.2")

    expect(client.config).to eq(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "api-user",
      client_ip: "192.0.2.1",
      environment: "sandbox"
    )
    expect(other.config).not_to equal(client.config)
    expect(client.config).to be_frozen
  end

  it "prevents configuration from being changed after construction" do
    expect { client.config[:client_ip] = "192.0.2.2" }.to raise_error(FrozenError)
  end

  it "accepts an explicit username and production environment" do
    configured = described_class.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1",
      environment: "production"
    )

    expect(configured.config).to include(user_name: "account-user", environment: "production")
  end

  %i[api_user api_key user_name client_ip].each do |option|
    it "rejects a blank #{option}" do
      options = {api_user: "api-user", api_key: "api-key", user_name: "account-user", client_ip: "192.0.2.1"}
      options[option] = ""

      expect { described_class.new(**options) }.to raise_error(ArgumentError, "#{option} must be provided")
    end
  end

  it "requires client_ip" do
    expect { described_class.new(api_user: "api-user", api_key: "api-key") }
      .to raise_error(ArgumentError, /missing keyword: :client_ip/)
  end

  it "rejects unknown environments" do
    expect do
      described_class.new(api_user: "api-user", api_key: "api-key", client_ip: "192.0.2.1", environment: "staging")
    end.to raise_error(ArgumentError, "environment must be sandbox or production")
  end

  it "creates a domains resource" do
    expect(client.domains).to be_a(Namecheap::API::Domains)
  end

  it "creates a users resource" do
    expect(client.users).to be_a(Namecheap::API::Users)
  end

  it "creates an SSL resource" do
    expect(client.ssl).to be_a(Namecheap::API::Ssl)
  end

  it "creates a domain privacy resource" do
    expect(client.domain_privacy).to be_a(Namecheap::API::DomainPrivacy)
  end
end
