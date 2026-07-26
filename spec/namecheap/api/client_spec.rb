require "spec_helper"

RSpec.describe Namecheap::API::Client do
  subject(:client) do
    described_class.new(
      api_user: "api-user",
      api_key: "api-key",
      client_ip: "192.0.2.1"
    )
  end

  it "exposes only the nonsecret environment" do
    expect(client.environment).to eq("sandbox")
    expect(client).not_to respond_to(:config)
  end

  it "copies credential values before storing them" do
    api_key = +"api-key"
    configured = described_class.new(api_user: "api-user", api_key: api_key, client_ip: "192.0.2.1")
    api_key.replace("changed")

    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("ApiKey" => "api-key"))
      .to_return(body: "<ApiResponse Status=\"OK\"/>")
    configured.domains.get_list

    expect(request).to have_been_requested.once
  end

  it "accepts an explicit username and production environment" do
    configured = described_class.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1",
      environment: "production"
    )

    expect(configured.environment).to eq("production")
  end

  it "configures safe default request timeouts" do
    connection = instance_double(Faraday::Connection)
    expect(Namecheap::API::Base).to receive(:build_connection)
      .with(open_timeout: 5, read_timeout: 30)
      .and_return(connection)

    described_class.new(api_user: "api-user", api_key: "api-key", client_ip: "192.0.2.1")
  end

  it "accepts custom finite request timeouts" do
    connection = instance_double(Faraday::Connection)
    expect(Namecheap::API::Base).to receive(:build_connection)
      .with(open_timeout: 0.5, read_timeout: 45)
      .and_return(connection)

    described_class.new(
      api_user: "api-user",
      api_key: "api-key",
      client_ip: "192.0.2.1",
      open_timeout: 0.5,
      read_timeout: 45
    )
  end

  it "maps open and read timeouts to Faraday connection options" do
    connection = Namecheap::API::Base.build_connection(open_timeout: 0.5, read_timeout: 45)

    expect(connection.options.open_timeout).to eq(0.5)
    expect(connection.options.timeout).to eq(45)
  end

  {
    zero: 0,
    negative: -1,
    nan: Float::NAN,
    infinity: Float::INFINITY,
    string: "30",
    nil: nil,
    complex: Complex(1, 1)
  }.each do |description, value|
    %i[open_timeout read_timeout].each do |option|
      it "rejects a #{description} #{option}" do
        expect do
          described_class.new(
            api_user: "api-user",
            api_key: "api-key",
            client_ip: "192.0.2.1",
            **{option => value}
          )
        end.to raise_error(ArgumentError, "#{option} must be a positive finite number")
      end
    end
  end

  it "shares one connection with top-level and nested resources" do
    connection = instance_double(Faraday::Connection)
    allow(Namecheap::API::Base).to receive(:build_connection).and_return(connection)
    configured = described_class.new(api_user: "api-user", api_key: "api-key", client_ip: "192.0.2.1")

    resources = [
      configured.domains,
      configured.domains.dns,
      configured.domains.nameservers,
      configured.domains.transfers,
      configured.ssl,
      configured.users,
      configured.users.addresses,
      configured.domain_privacy
    ]

    expect(resources.map { |resource| resource.instance_variable_get(:@connection) })
      .to all(be(connection))
    expect(Namecheap::API::Base).to have_received(:build_connection).once
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

  it "rejects malformed credential types and client addresses" do
    expect { described_class.new(api_user: :user, api_key: "key", client_ip: "192.0.2.1") }
      .to raise_error(ArgumentError, "api_user must be a string")
    expect { described_class.new(api_user: " user ", api_key: "key", client_ip: "192.0.2.1") }
      .to raise_error(ArgumentError, "api_user must not contain surrounding whitespace")
    expect { described_class.new(api_user: "user", api_key: "key", client_ip: "not-an-ip") }
      .to raise_error(ArgumentError, "client_ip must be an IPv4 address")
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
