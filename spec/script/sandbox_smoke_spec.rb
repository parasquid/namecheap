require "spec_helper"
require "stringio"
require "tempfile"
load File.expand_path("../../script/sandbox_smoke", __dir__)

RSpec.describe SandboxSmoke do
  let(:environment) do
    {
      "NAMECHEAP_API_USER" => "sandbox-user",
      "NAMECHEAP_API_KEY" => "sandbox-key",
      "NAMECHEAP_CLIENT_IP" => "192.0.2.1",
      "NAMECHEAP_ENVIRONMENT" => "sandbox"
    }
  end
  let(:domains) { instance_double(Namecheap::API::Domains) }
  let(:transfers) { instance_double(Namecheap::API::Transfers) }
  let(:ssl) { instance_double(Namecheap::API::Ssl) }
  let(:users) { instance_double(Namecheap::API::Users) }
  let(:privacy) { instance_double(Namecheap::API::DomainPrivacy) }
  let(:client) do
    instance_double(
      Namecheap::API::Client,
      domains: domains,
      ssl: ssl,
      users: users,
      domain_privacy: privacy
    )
  end
  let(:output) { StringIO.new }

  def response(result = nil)
    result ||= "<CommandResponse/>"
    "<ApiResponse Status=\"OK\">#{result}</ApiResponse>"
  end

  it "runs safe checks without making lifecycle requests" do
    allow(domains).to receive(:get_tld_list).and_return(response)
    allow(domains).to receive(:get_list).and_return(response)
    allow(domains).to receive(:transfers).and_return(transfers)
    allow(transfers).to receive(:get_list).and_return(response)
    allow(ssl).to receive(:get_list).and_return(response)
    allow(users).to receive(:get_balances).and_return(response)
    allow(privacy).to receive(:get_list).and_return(response)
    allow(domains).to receive(:check).with(domain_names: [kind_of(String)])
      .and_return(response("<DomainCheckResult Available=\"true\"/>"))
    expect(domains).not_to receive(:create)

    described_class.new(env: environment, output: output, client: client).run

    expect(output.string).to include("Safe sandbox smoke checks passed.")
    expect(output.string).to include("ruby-dns-check-")
    expect(output.string).not_to include("namecheap")
  end

  it "refuses production and incomplete staging environments" do
    expect do
      described_class.new(env: environment.merge("NAMECHEAP_ENVIRONMENT" => "production"), client: client)
    end.to raise_error(RuntimeError, /refuse/)

    expect do
      described_class.new(env: environment.reject { |key| key == "NAMECHEAP_API_KEY" }, client: client)
    end.to raise_error(RuntimeError, /NAMECHEAP_API_KEY/)
  end
end

RSpec.describe SandboxEnvironment do
  it "loads staging values without evaluating shell code" do
    file = Tempfile.new("namecheap-staging")
    file.write(<<~ENV)
      # sandbox only
      NAMECHEAP_API_USER='sandbox-user'
      NAMECHEAP_API_KEY="sandbox-key"
      NAMECHEAP_CLIENT_IP=192.0.2.1
    ENV
    file.close
    environment = {}

    described_class.load!(file.path, env: environment)

    expect(environment).to include(
      "NAMECHEAP_API_USER" => "sandbox-user",
      "NAMECHEAP_API_KEY" => "sandbox-key",
      "NAMECHEAP_CLIENT_IP" => "192.0.2.1"
    )
  ensure
    file&.unlink
  end
end
