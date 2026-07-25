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

  def response_xml(value)
    "<ApiResponse Status=\"OK\"><CommandResponse><TestResult Value=\"#{value}\"/></CommandResponse></ApiResponse>"
  end

  it "lists domains against sandbox and returns a parsed response with raw access" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.getList", "Page" => "2", "SearchTerm" => "hello world"))
      .to_return(body: "<ApiResponse Status=\"OK\"/>")

    response = build_client.domains.get_list(params: {Page: 2, SearchTerm: "hello world"})

    expect(response).to be_a(Namecheap::API::Response)
    expect(response.raw_body).to eq("<ApiResponse Status=\"OK\"/>")
    expect(request).to have_been_requested.once
  end

  it "uses the production endpoint when requested" do
    request = stub_request(:get, Namecheap::API::Base::PRODUCTION)
      .with(query: credentials.merge("Command" => "namecheap.domains.getList"))
      .to_return(body: response_xml("production"))

    expect(build_client(environment: "production").domains.get_list.data).to eq(value: "production")
    expect(request).to have_been_requested.once
  end

  it "protects credentials and command from caller overrides" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.getList"))
      .to_return(body: response_xml("protected"))

    response = build_client.domains.get_list(
      params: {ApiKey: "override", ClientIp: "203.0.113.1", Command: "namecheap.users.getBalances"}
    )

    expect(response.data).to eq(value: "protected")
    expect(request).to have_been_requested.once
  end

  it "gets domain contacts" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.getContacts", "DomainName" => "example.com"))
      .to_return(body: response_xml("contacts"))

    response = build_client.domains.get_contacts(domain_name: "example.com", params: {DomainName: "override"})
    expect(response.data).to eq(value: "contacts")
    expect(request).to have_been_requested.once
  end

  it "lists domain nameservers through the nested DNS resource" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge("Command" => "namecheap.domains.dns.getList", "SLD" => "example", "TLD" => "com"))
      .to_return(body: response_xml("dns"))

    response = build_client.domains.dns.get_list(sld: "example", tld: "com", params: {SLD: "override"})
    expect(response.data).to eq(value: "dns")
    expect(request).to have_been_requested.once
  end

  it "gets product pricing" do
    request = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(
        query: credentials.merge(
          "Command" => "namecheap.users.getPricing",
          "ProductType" => "DOMAIN",
          "ProductCategory" => "DOMAINS",
          "ActionName" => "REGISTER",
          "ProductName" => "COM"
        )
      )
      .to_return(body: response_xml("pricing"))

    response = build_client.users.get_pricing(
      product_type: "DOMAIN",
      params: {
        ProductType: "override",
        ProductCategory: "DOMAINS",
        ActionName: "REGISTER",
        ProductName: "COM"
      }
    )

    expect(response.data).to eq(value: "pricing")
    expect(request).to have_been_requested.once
  end
end
