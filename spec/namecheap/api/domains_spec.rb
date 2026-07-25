require "spec_helper"

RSpec.describe Namecheap::API::Domains do
  let(:credentials) do
    {
      "ApiUser" => "api-user",
      "ApiKey" => "api-key",
      "UserName" => "account-user",
      "ClientIp" => "192.0.2.1"
    }
  end
  let(:contact) do
    {
      first_name: "Example",
      last_name: "Person",
      address_1: "1 Example Street",
      city: "Example City",
      state_province: "CA",
      postal_code: "90210",
      country: "US",
      phone: "+1.5555550100",
      email_address: "person@example.com",
      organization_name: "Example Org"
    }
  end

  def domains
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    ).domains
  end

  def contact_query(prefix)
    {
      "#{prefix}FirstName" => "Example",
      "#{prefix}LastName" => "Person",
      "#{prefix}Address1" => "1 Example Street",
      "#{prefix}City" => "Example City",
      "#{prefix}StateProvince" => "CA",
      "#{prefix}PostalCode" => "90210",
      "#{prefix}Country" => "US",
      "#{prefix}Phone" => "+1.5555550100",
      "#{prefix}EmailAddress" => "person@example.com",
      "#{prefix}OrganizationName" => "Example Org"
    }
  end

  def all_contacts
    %w[Registrant Tech Admin AuxBilling].each_with_object({}) do |prefix, result|
      result.merge!(contact_query(prefix))
    end
  end

  def stub_get(command, params = {})
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge(params).merge("Command" => command))
      .to_return(body: response_xml(command))
  end

  def response_xml(value)
    "<ApiResponse Status=\"OK\"><CommandResponse><TestResult Value=\"#{value}\"/></CommandResponse></ApiResponse>"
  end

  it "creates a domain using a form-encoded POST" do
    body = credentials
      .merge("PromotionCode" => "SAVE", "DomainName" => "example.com", "Years" => "1")
      .merge(all_contacts)
      .merge("Command" => "namecheap.domains.create")
    request = stub_request(:post, Namecheap::API::Base::SANDBOX)
      .with(body: body)
      .to_return(body: response_xml("created"))

    response = domains.create(
      domain_name: "example.com",
      years: 1,
      registrant: contact,
      tech: contact,
      admin: contact,
      aux_billing: contact,
      params: {PromotionCode: "SAVE", DomainName: "override", ApiKey: "override"}
    )

    expect(response.data).to eq(value: "created")
    expect(request).to have_been_requested.once
  end

  it "lists TLDs" do
    request = stub_get("namecheap.domains.getTldList")

    expect(domains.get_tld_list.data).to eq(value: "namecheap.domains.getTldList")
    expect(request).to have_been_requested.once
  end

  it "sets all contact groups" do
    request = stub_get(
      "namecheap.domains.setContacts",
      all_contacts.merge("DomainName" => "example.com", "RegistrantNexus" => "C11")
    )

    response = domains.set_contacts(
      domain_name: "example.com",
      registrant: contact,
      tech: contact,
      admin: contact,
      aux_billing: contact,
      params: {RegistrantNexus: "C11"}
    )

    expect(response.data).to eq(value: "namecheap.domains.setContacts")
    expect(request).to have_been_requested.once
  end

  it "checks a list of domains" do
    request = stub_get("namecheap.domains.check", "DomainList" => "example.com,example.net")

    expect(domains.check(domain_names: ["example.com", "example.net"]).data).to eq(value: "namecheap.domains.check")
    expect(request).to have_been_requested.once
  end

  it "reactivates a domain" do
    request = stub_get("namecheap.domains.reactivate", "DomainName" => "example.com", "YearsToAdd" => "1")

    expect(domains.reactivate(domain_name: "example.com", years_to_add: 1).data).to eq(value: "namecheap.domains.reactivate")
    expect(request).to have_been_requested.once
  end

  it "renews a domain with required years" do
    request = stub_get("namecheap.domains.renew", "DomainName" => "example.com", "Years" => "2")

    expect(domains.renew(domain_name: "example.com", years: 2).data).to eq(value: "namecheap.domains.renew")
    expect(request).to have_been_requested.once
  end

  it "gets the registrar lock" do
    request = stub_get("namecheap.domains.getRegistrarLock", "DomainName" => "example.com")

    expect(domains.get_registrar_lock(domain_name: "example.com").data).to eq(value: "namecheap.domains.getRegistrarLock")
    expect(request).to have_been_requested.once
  end

  it "sets the registrar lock" do
    request = stub_get("namecheap.domains.setRegistrarLock", "DomainName" => "example.com", "LockAction" => "UNLOCK")

    expect(domains.set_registrar_lock(domain_name: "example.com", params: {LockAction: "UNLOCK"}).data).to eq(value: "namecheap.domains.setRegistrarLock")
    expect(request).to have_been_requested.once
  end

  it "gets domain information" do
    request = stub_get("namecheap.domains.getInfo", "DomainName" => "example.com", "HostName" => "www.example.com")

    expect(domains.get_info(domain_name: "example.com", host_name: "www.example.com").data).to eq(value: "namecheap.domains.getInfo")
    expect(request).to have_been_requested.once
  end

  it "rejects incomplete contact groups before requesting" do
    expect do
      domains.create(
        domain_name: "example.com",
        years: 1,
        registrant: contact.reject { |field| field == :phone },
        tech: contact,
        admin: contact,
        aux_billing: contact
      )
    end.to raise_error(ArgumentError, "Registrant.phone must be provided")
  end

  it "rejects unknown structured contact fields" do
    expect do
      domains.set_contacts(
        domain_name: "example.com",
        registrant: contact.merge(firstname: "Typo"),
        tech: contact,
        admin: contact,
        aux_billing: contact
      )
    end.to raise_error(ArgumentError, "Registrant contains unknown field firstname")
  end

  it "rejects empty and oversized domain lists" do
    expect { domains.check(domain_names: []) }.to raise_error(ArgumentError, /at least one/)
    expect { domains.check(domain_names: Array.new(51, "example.com")) }.to raise_error(ArgumentError, /more than 50/)
  end
end
