require "spec_helper"

RSpec.describe Namecheap::Api do
  subject(:api) { described_class.new }

  before { set_dummy_config }

  it "preserves the legacy init_args visibility" do
    expect(api).to respond_to(:init_args)
  end

  describe "configuration validation" do
    %i[username key client_ip].each do |option|
      it "identifies a missing #{option}" do
        Namecheap.config.public_send("#{option}=", nil)

        expect { api.get("domains.getList") }
          .to raise_error(Namecheap::Config::RequiredOptionMissing, /missing: #{option},/)
      end
    end
  end

  describe "request dispatch" do
    {
      get: :get,
      post: :post,
      put: :put,
      delete: :delete
    }.each do |public_method, http_method|
      it "dispatches #{public_method.to_s.upcase} with Namecheap parameters" do
        expect(HTTParty).to receive(http_method).with(
          described_class::ENDPOINT,
          query: {
            "ApiUser" => "the_username",
            "UserName" => "the_username",
            "ApiKey" => "the_key",
            "ClientIp" => "127.0.0.1",
            "DomainList" => "example.com",
            "Command" => "namecheap.domains.check"
          }
        ).and_return(:response)

        expect(api.public_send(public_method, "domains.check", domain_list: "example.com")).to eq(:response)
      end
    end

    it "lets caller options override defaults" do
      expect(HTTParty).to receive(:get).with(
        described_class::ENDPOINT,
        query: hash_including("ClientIp" => "192.0.2.10")
      )

      api.get("domains.getList", client_ip: "192.0.2.10")
    end

    it "forces sandbox requests independently of the inferred environment" do
      stub_const("#{described_class}::ENDPOINT", described_class::PRODUCTION)
      Namecheap.config.environment = "sandbox"

      expect(HTTParty).to receive(:get).with(described_class::SANDBOX, anything)

      api.get("domains.getList")
    end

    it "forces production requests independently of the inferred environment" do
      stub_const("#{described_class}::ENDPOINT", described_class::SANDBOX)
      Namecheap.config.environment = "production"

      expect(HTTParty).to receive(:get).with(described_class::PRODUCTION, anything)

      api.get("domains.getList")
    end
  end
end
