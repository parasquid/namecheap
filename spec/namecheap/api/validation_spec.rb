require "spec_helper"

RSpec.describe "Namecheap v2 scalar validation" do
  let(:client) do
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      client_ip: "192.0.2.1"
    )
  end

  it "rejects invalid domain strings and positive integer fields before HTTP" do
    expect { client.domains.get_info(domain_name: "") }
      .to raise_error(ArgumentError, "domain_name must be provided")
    expect { client.domains.renew(domain_name: "example.com", years: "1") }
      .to raise_error(ArgumentError, "years must be a positive integer")
    expect { client.domains.transfers.get_status(transfer_id: 0) }
      .to raise_error(ArgumentError, "transfer_id must be a positive integer")
  end

  it "rejects invalid certificate and address identifiers before HTTP" do
    expect { client.ssl.get_info(certificate_id: "10") }
      .to raise_error(ArgumentError, "certificate_id must be a positive integer")
    expect { client.users.addresses.get_info(address_id: -1) }
      .to raise_error(ArgumentError, "address_id must be a positive integer")
  end

  it "requires actual booleans" do
    profile = {
      first_name: "Example",
      last_name: "Person",
      address_1: "1 Example Street",
      city: "Example City",
      state_province: "CA",
      postal_code: "90210",
      country: "US",
      email_address: "person@example.com",
      phone: "+1.5555550100"
    }

    expect do
      client.users.create(user_name: "new-user", password: "password", profile: profile, accept_terms: 1)
    end.to raise_error(ArgumentError, "accept_terms must be true or false")
  end

  it "validates registered nameserver addresses as IPv4" do
    expect do
      client.domains.nameservers.create(sld: "example", tld: "com", nameserver: "ns1.example.com", ip: "invalid")
    end.to raise_error(ArgumentError, "ip must be an IPv4 address")
  end

  it "does not issue requests for invalid scalar inputs" do
    expect(a_request(:any, /namecheap/)).not_to have_been_made
  end
end
