require "spec_helper"

RSpec.describe Namecheap::API::Addresses do
  let(:credentials) do
    {
      "ApiUser" => "api-user",
      "ApiKey" => "api-key",
      "UserName" => "account-user",
      "ClientIp" => "192.0.2.1"
    }
  end
  let(:client) do
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    )
  end
  let(:address) do
    {
      email_address: "person@example.com",
      first_name: "Example",
      last_name: "Person",
      address_1: "1 Example Street",
      city: "Example City",
      state_province: "CA",
      state_province_choice: "P",
      postal_code: "90210",
      country: "US",
      phone: "+1.5555550100"
    }
  end
  let(:response_body) do
    "<ApiResponse Status=\"OK\"><CommandResponse><AddressResult Success=\"true\"/></CommandResponse></ApiResponse>"
  end

  def expect_request(method, command, params)
    request = stub_request(method, Namecheap::API::Base::SANDBOX)
    expected = credentials.merge(params).merge("Command" => command).transform_values(&:to_s)
    (method == :get) ? request.with(query: expected) : request.with(body: expected)
    request.to_return(body: response_body)
  end

  it "exposes the nested resource and implements all address commands" do
    resource = client.users.addresses
    expect(resource).to be_a(described_class)

    create = expect_request(
      :post,
      "namecheap.users.address.create",
      {
        "AddressName" => "primary",
        "DefaultYN" => 1,
        "EmailAddress" => "person@example.com",
        "FirstName" => "Example",
        "LastName" => "Person",
        "Address1" => "1 Example Street",
        "City" => "Example City",
        "StateProvince" => "CA",
        "StateProvinceChoice" => "P",
        "Zip" => "90210",
        "Country" => "US",
        "Phone" => "+1.5555550100"
      }
    )
    resource.create(address_name: "primary", address: address, default: true)
    expect(create).to have_been_requested.once

    {
      delete: [:post, "namecheap.users.address.delete"],
      get_info: [:get, "namecheap.users.address.getInfo"],
      set_default: [:post, "namecheap.users.address.setDefault"]
    }.each do |method, (verb, command)|
      request = expect_request(verb, command, "AddressId" => 10)
      resource.public_send(method, address_id: 10)
      expect(request).to have_been_requested.once
    end

    list = expect_request(:get, "namecheap.users.address.getList", {})
    resource.get_list
    expect(list).to have_been_requested.once

    update = expect_request(
      :post,
      "namecheap.users.address.update",
      {
        "AddressId" => 10,
        "AddressName" => "work",
        "DefaultYN" => 0,
        "EmailAddress" => "person@example.com",
        "FirstName" => "Example",
        "LastName" => "Person",
        "Address1" => "1 Example Street",
        "City" => "Example City",
        "StateProvince" => "CA",
        "StateProvinceChoice" => "P",
        "Zip" => "90210",
        "Country" => "US",
        "Phone" => "+1.5555550100"
      }
    )
    resource.update(address_id: 10, address_name: "work", address: address, default: false)
    expect(update).to have_been_requested.once
  end

  it "validates structured address input before requesting" do
    expect do
      client.users.addresses.create(
        address_name: "bad",
        address: address.except(:state_province_choice)
      )
    end.to raise_error(ArgumentError, "address.state_province_choice must be provided")
  end
end
