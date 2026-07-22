require "spec_helper"

RSpec.describe "Namecheap v2 requests" do
  let(:credentials) do
    {
      "ApiUser" => "api-user",
      "ApiKey" => "api-key",
      "UserName" => "account-user",
      "ClientIp" => "192.0.2.1"
    }
  end

  def build_client(environment: "sandbox")
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1",
      environment: environment
    )
  end

  it "lists domains against sandbox and returns the raw body" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.getList", "Page" => "2", "SearchTerm" => "hello world"))
      .to_return(body: "<ApiResponse Status=\"OK\"/>")

    response = build_client.domains.get_list(params: {Page: 2, SearchTerm: "hello world"})

    expect(response).to eq("<ApiResponse Status=\"OK\"/>")
    expect(request).to have_been_requested.once
  end

  it "uses the production endpoint when requested" do
    request = stub_request(:get, Namecheap::API::Base::PRODUCTION)
      .with(query: credentials.merge("Command" => "namecheap.domains.getList"))
      .to_return(body: "production")

    expect(build_client(environment: "production").domains.get_list).to eq("production")
    expect(request).to have_been_requested.once
  end

  it "protects credentials and command from caller overrides" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.getList"))
      .to_return(body: "protected")

    response = build_client.domains.get_list(
      params: {ApiKey: "override", ClientIp: "203.0.113.1", Command: "namecheap.users.getBalances"}
    )

    expect(response).to eq("protected")
    expect(request).to have_been_requested.once
  end

  it "gets domain contacts" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.getContacts", "DomainName" => "example.com"))
      .to_return(body: "contacts")

    expect(build_client.domains.get_contacts(domain_name: "example.com")).to eq("contacts")
    expect(request).to have_been_requested.once
  end

  it "lists domain nameservers through the nested DNS resource" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.dns.getList", "SLD" => "example", "TLD" => "com"))
      .to_return(body: "dns")

    expect(build_client.domains.dns.get_list(sld: "example", tld: "com")).to eq("dns")
    expect(request).to have_been_requested.once
  end

  it "marks domain creation as unfinished" do
    expect do
      build_client.domains.create(
        domain_name: "example.com",
        years: 1,
        registrant_first_name: "Example",
        registrant_last_name: "Person",
        registrant_address_1: "1 Example Street",
        registrant_city: "Example",
        registrant_state_province: "CA",
        registrant_postal_code: "90210",
        registrant_country: "US",
        registrant_phone: "+1.5555550100",
        registrant_email_address: "person@example.com"
      )
    end.to raise_error(NotImplementedError, /Domain creation/)
  end
end
