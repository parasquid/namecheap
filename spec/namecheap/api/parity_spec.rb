require "spec_helper"

RSpec.describe "Namecheap v2 parity resources" do
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
  let(:profile) do
    {
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
  end

  def expect_request(method, command, params, include_user_name: true)
    expected_credentials = include_user_name ? credentials : credentials.except("UserName")
    request = stub_request(method, Namecheap::API::Base::SANDBOX)
    expected = expected_credentials.merge(params).merge("Command" => command).transform_values(&:to_s)
    (method == :get) ? request.with(query: expected) : request.with(body: expected)
    request.to_return(body: command)
    request
  end

  def verify(method, command, params = nil, include_user_name: true, **keyword_params)
    params ||= keyword_params
    request = expect_request(method, command, params, include_user_name: include_user_name)
    expect(yield).to eq(command)
    expect(request).to have_been_requested.once
  end

  it "exposes all parity resources" do
    expect(client.domains.nameservers).to be_a(Namecheap::API::Nameservers)
    expect(client.domains.transfers).to be_a(Namecheap::API::Transfers)
    expect(client.ssl).to be_a(Namecheap::API::Ssl)
    expect(client.domain_privacy).to be_a(Namecheap::API::DomainPrivacy)
  end

  it "implements registered nameserver commands" do
    resource = client.domains.nameservers
    verify(:post, "namecheap.domains.ns.create", "SLD" => "example", "TLD" => "com", "Nameserver" => "ns1.example.com", "IP" => "192.0.2.10") do
      resource.create(sld: "example", tld: "com", nameserver: "ns1.example.com", ip: "192.0.2.10")
    end
    verify(:post, "namecheap.domains.ns.delete", "SLD" => "example", "TLD" => "com", "Nameserver" => "ns1.example.com") do
      resource.delete(sld: "example", tld: "com", nameserver: "ns1.example.com")
    end
    verify(:get, "namecheap.domains.ns.getInfo", "SLD" => "example", "TLD" => "com", "Nameserver" => "ns1.example.com") do
      resource.get_info(sld: "example", tld: "com", nameserver: "ns1.example.com")
    end
    verify(:post, "namecheap.domains.ns.update", "SLD" => "example", "TLD" => "com", "Nameserver" => "ns1.example.com", "OldIP" => "192.0.2.10", "IP" => "192.0.2.11") do
      resource.update(
        sld: "example",
        tld: "com",
        nameserver: "ns1.example.com",
        old_ip: "192.0.2.10",
        ip: "192.0.2.11"
      )
    end
  end

  it "implements domain transfer commands" do
    resource = client.domains.transfers
    verify(:post, "namecheap.domains.transfer.create", "DomainName" => "example.com", "Years" => 1, "EPPCode" => "transfer-code") do
      resource.create(domain_name: "example.com", years: 1, epp_code: "transfer-code")
    end
    verify(:get, "namecheap.domains.transfer.getStatus", "TransferID" => 15) do
      resource.get_status(transfer_id: 15)
    end
    verify(:post, "namecheap.domains.transfer.updateStatus", "TransferID" => 15, "Resubmit" => true) do
      resource.update_status(transfer_id: 15, resubmit: true)
    end
    verify(:get, "namecheap.domains.transfer.getList", "Page" => 2) do
      resource.get_list(params: {Page: 2})
    end
  end

  it "implements SSL commands" do
    resource = client.ssl
    verify(:post, "namecheap.ssl.create", "Years" => 1, "Type" => "Standard SSL SSLcom") do
      resource.create(years: 1, certificate_type: "Standard SSL SSLcom")
    end
    verify(:get, "namecheap.ssl.getList", "Page" => 2) { resource.get_list(params: {Page: 2}) }
    verify(:post, "namecheap.ssl.parseCSR", "csr" => "CSR") { resource.parse_csr(csr: "CSR") }
    verify(:get, "namecheap.ssl.getApproverEmailList", "DomainName" => "example.com", "CertificateType" => "Standard SSL SSLcom") do
      resource.get_approver_email_list(domain_name: "example.com", certificate_type: "Standard SSL SSLcom")
    end
    verify(:post, "namecheap.ssl.activate", "CertificateID" => 10, "CSR" => "CSR") do
      resource.activate(certificate_id: 10, csr: "CSR")
    end
    verify(:post, "namecheap.ssl.resendApproverEmail", "CertificateID" => 10) do
      resource.resend_approver_email(certificate_id: 10)
    end
    verify(:get, "namecheap.ssl.getInfo", "CertificateID" => 10) { resource.get_info(certificate_id: 10) }
    verify(:post, "namecheap.ssl.renew", "CertificateID" => 10, "Years" => 1, "SSLType" => "Standard SSL SSLcom") do
      resource.renew(certificate_id: 10, years: 1, certificate_type: "Standard SSL SSLcom")
    end
    verify(:post, "namecheap.ssl.reissue", "CertificateID" => 10, "CSR" => "CSR") do
      resource.reissue(certificate_id: 10, csr: "CSR")
    end
    verify(:post, "namecheap.ssl.resendfulfillmentemail", "CertificateID" => 10) do
      resource.resend_fulfillment_email(certificate_id: 10)
    end
  end

  it "implements user commands and controlled UserName omission" do
    resource = client.users
    verify(:get, "namecheap.users.getBalances", {}) { resource.get_balances }
    verify(
      :post,
      "namecheap.users.create",
      profile_params.merge("NewUserName" => "new-user", "NewUserPassword" => "new-password", "AcceptTerms" => 1)
    ) { resource.create(user_name: "new-user", password: "new-password", profile: profile, accept_terms: 1) }
    verify(:post, "namecheap.users.update", profile_params) { resource.update(profile: profile) }
    verify(:post, "namecheap.users.changePassword", {"NewPassword" => "new", "OldPassword" => "old"}) do
      resource.change_password(new_password: "new", old_password: "old")
    end
    verify(
      :post,
      "namecheap.users.changePassword",
      {"NewPassword" => "new", "ResetCode" => "reset"},
      include_user_name: false
    ) { resource.change_password(new_password: "new", reset_code: "reset") }
    verify(
      :post,
      "namecheap.users.createaddfundsrequest",
      {"Username" => "new-user", "PaymentType" => "CreditCard", "Amount" => 40, "ReturnUrl" => "https://example.com/return"}
    ) do
      resource.create_add_funds_request(
        user_name: "new-user",
        payment_type: "CreditCard",
        amount: 40,
        return_url: "https://example.com/return"
      )
    end
    verify(:get, "namecheap.users.getAddFundsStatus", "TokenId" => "token") do
      resource.get_add_funds_status(token_id: "token")
    end
    verify(:post, "namecheap.users.login", "Password" => "password") { resource.login(password: "password") }
    verify(
      :post,
      "namecheap.users.resetPassword",
      {"FindBy" => "USERNAME", "FindByValue" => "new-user"},
      include_user_name: false
    ) { resource.reset_password(find_by: "USERNAME", find_by_value: "new-user") }
  end

  it "validates user profile and password-change modes" do
    expect { client.users.update(profile: profile.except(:phone)) }
      .to raise_error(ArgumentError, "profile.phone must be provided")
    expect { client.users.update(profile: profile.merge(typo: "value")) }
      .to raise_error(ArgumentError, "profile contains unknown field typo")
    expect { client.users.change_password(new_password: "new") }
      .to raise_error(ArgumentError, /exactly one/)
    expect { client.users.change_password(new_password: "new", old_password: "old", reset_code: "reset") }
      .to raise_error(ArgumentError, /exactly one/)
  end

  it "implements current domain privacy commands" do
    resource = client.domain_privacy
    verify(:post, "namecheap.whoisguard.changeemailaddress", "WhoisguardID" => 10) do
      resource.change_email_address(whoisguard_id: 10)
    end
    verify(:post, "namecheap.whoisguard.enable", "WhoisguardID" => 10, "ForwardedToEmail" => "person@example.com") do
      resource.enable(whoisguard_id: 10, forwarded_to_email: "person@example.com")
    end
    verify(:post, "namecheap.whoisguard.disable", "WhoisguardID" => 10) do
      resource.disable(whoisguard_id: 10)
    end
    verify(:get, "namecheap.whoisguard.getList", "Page" => 2) { resource.get_list(params: {Page: 2}) }
    verify(:post, "namecheap.whoisguard.renew", "WhoisguardID" => 10, "Years" => 1) do
      resource.renew(whoisguard_id: 10, years: 1)
    end
  end

  it "never restores protected fields when UserName is omitted" do
    verify(
      :post,
      "namecheap.users.resetPassword",
      {"FindBy" => "USERNAME", "FindByValue" => "new-user"},
      include_user_name: false
    ) do
      client.users.reset_password(
        find_by: "USERNAME",
        find_by_value: "new-user",
        params: {UserName: "override", ApiKey: "override", Command: "override"}
      )
    end
  end

  def profile_params
    {
      "FirstName" => "Example",
      "LastName" => "Person",
      "Address1" => "1 Example Street",
      "City" => "Example City",
      "StateProvince" => "CA",
      "Zip" => "90210",
      "Country" => "US",
      "EmailAddress" => "person@example.com",
      "Phone" => "+1.5555550100"
    }
  end
end
