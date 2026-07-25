require "spec_helper"

RSpec.describe Namecheap::API::Dns do
  let(:credentials) do
    {
      "ApiUser" => "api-user",
      "ApiKey" => "api-key",
      "UserName" => "account-user",
      "ClientIp" => "192.0.2.1"
    }
  end

  def dns
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    ).domains.dns
  end

  def stub_get(command, params = {})
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: credentials.merge(params).merge("Command" => command))
      .to_return(body: response_xml(command))
  end

  def response_xml(value)
    "<ApiResponse Status=\"OK\"><CommandResponse><TestResult Value=\"#{value}\"/></CommandResponse></ApiResponse>"
  end

  it "sets Namecheap default DNS" do
    request = stub_get("namecheap.domains.dns.setDefault", "SLD" => "example", "TLD" => "com")

    expect(dns.set_default(sld: "example", tld: "com").data).to eq(value: "namecheap.domains.dns.setDefault")
    expect(request).to have_been_requested.once
  end

  it "sets custom nameservers from an array" do
    request = stub_get(
      "namecheap.domains.dns.setCustom",
      "SLD" => "example",
      "TLD" => "com",
      "Nameservers" => "ns1.example.net,ns2.example.net"
    )

    response = dns.set_custom(
      sld: "example",
      tld: "com",
      nameservers: ["ns1.example.net", "ns2.example.net"]
    )

    expect(response.data).to eq(value: "namecheap.domains.dns.setCustom")
    expect(request).to have_been_requested.once
  end

  it "gets host records" do
    request = stub_get("namecheap.domains.dns.getHosts", "SLD" => "example", "TLD" => "com")

    expect(dns.get_hosts(sld: "example", tld: "com").data).to eq(value: "namecheap.domains.dns.getHosts")
    expect(request).to have_been_requested.once
  end

  it "gets email forwarding" do
    request = stub_get("namecheap.domains.dns.getEmailForwarding", "DomainName" => "example.com")

    expect(dns.get_email_forwarding(domain_name: "example.com").data).to eq(value: "namecheap.domains.dns.getEmailForwarding")
    expect(request).to have_been_requested.once
  end

  it "serializes indexed email forwardings" do
    request = stub_get(
      "namecheap.domains.dns.setEmailForwarding",
      "DomainName" => "example.com",
      "MailBox1" => "info",
      "ForwardTo1" => "person@example.net",
      "MailBox2" => "jobs",
      "ForwardTo2" => "jobs@example.net"
    )

    response = dns.set_email_forwarding(
      domain_name: "example.com",
      forwardings: [
        {mailbox: "info", forward_to: "person@example.net"},
        {"mailbox" => "jobs", "forward_to" => "jobs@example.net"}
      ]
    )

    expect(response.data).to eq(value: "namecheap.domains.dns.setEmailForwarding")
    expect(request).to have_been_requested.once
  end

  it "replaces host records using a form-encoded POST" do
    body = credentials.merge(
      "Command" => "namecheap.domains.dns.setHosts",
      "SLD" => "example",
      "TLD" => "com",
      "EmailType" => "MX",
      "HostName1" => "@",
      "RecordType1" => "A",
      "Address1" => "192.0.2.10",
      "TTL1" => "1800",
      "HostName2" => "@",
      "RecordType2" => "MX",
      "Address2" => "mail.example.net",
      "MXPref2" => "10"
    )
    request = stub_request(:post, Namecheap::API::Base::SANDBOX)
      .with(body: body)
      .to_return(body: response_xml("hosts"))

    response = dns.set_hosts(
      sld: "example",
      tld: "com",
      email_type: "MX",
      records: [
        {host_name: "@", record_type: "A", address: "192.0.2.10", ttl: 1800},
        {host_name: "@", record_type: "MX", address: "mail.example.net", mx_pref: 10}
      ],
      params: {SLD: "override"}
    )

    expect(response.data).to eq(value: "hosts")
    expect(request).to have_been_requested.once
  end

  it "rejects empty nameserver and forwarding collections" do
    expect { dns.set_custom(sld: "example", tld: "com", nameservers: []) }.to raise_error(ArgumentError, /at least one/)
    expect { dns.set_email_forwarding(domain_name: "example.com", forwardings: []) }.to raise_error(ArgumentError, /non-empty array/)
  end

  it "rejects incomplete forwarding entries" do
    expect do
      dns.set_email_forwarding(domain_name: "example.com", forwardings: [{mailbox: "info"}])
    end.to raise_error(ArgumentError, "forwardings[0].forward_to must be provided")
  end

  it "requires MX preference for MX records" do
    expect do
      dns.set_hosts(
        sld: "example",
        tld: "com",
        email_type: "MX",
        records: [{host_name: "@", record_type: "MX", address: "mail.example.net"}]
      )
    end.to raise_error(ArgumentError, "records[0].mx_pref must be provided for MX records")
  end

  it "requires an email type and complete host records" do
    records = [{host_name: "@", record_type: "A", address: "192.0.2.10"}]

    expect { dns.set_hosts(sld: "example", tld: "com", email_type: nil, records: records) }
      .to raise_error(ArgumentError, "email_type must be provided")
    expect { dns.set_hosts(sld: "example", tld: "com", email_type: "MX", records: [{host_name: "@"}]) }
      .to raise_error(ArgumentError, "records[0].record_type must be provided")
  end
end
