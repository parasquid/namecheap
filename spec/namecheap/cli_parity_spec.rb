require "spec_helper"
require "namecheap/cli"
require "json"
require "stringio"
require "tmpdir"

RSpec.describe "Namecheap CLI parity" do
  def credentials
    {
      "NAMECHEAP_API_USER" => "api-user",
      "NAMECHEAP_API_KEY" => "api-key",
      "NAMECHEAP_USERNAME" => "account-user",
      "NAMECHEAP_CLIENT_IP" => "192.0.2.1",
      "NAMECHEAP_ENVIRONMENT" => "sandbox"
    }
  end

  def run_cli(*arguments, stdin: StringIO.new)
    stdout = StringIO.new
    stderr = StringIO.new
    code = Namecheap::CLI.run(
      arguments,
      stdout: stdout,
      stderr: stderr,
      stdin: stdin,
      env: {"HOME" => @directory}.merge(credentials)
    )
    [code, stdout.string, stderr.string]
  end

  def private_document(name, content)
    path = File.join(@directory, name)
    File.write(path, JSON.generate(content))
    File.chmod(0o600, path)
    path
  end

  def expected_commands
    %w[
      domain-privacy.disable
      domain-privacy.email.rotate
      domain-privacy.enable
      domain-privacy.list
      domain-privacy.renew
      dns.forwarding.set
      domains.contacts.set
      domains.nameservers.create
      domains.nameservers.delete
      domains.nameservers.info
      domains.nameservers.update
      domains.reactivate
      domains.transfers.create
      domains.transfers.list
      domains.transfers.resubmit
      domains.transfers.status
      ssl.activate
      ssl.approver-emails
      ssl.create
      ssl.info
      ssl.list
      ssl.parse-csr
      ssl.reissue
      ssl.renew
      ssl.resend.approver
      ssl.resend.fulfillment
      ssl.sans.purchase
      ssl.revoke
      ssl.dcv.edit
      users.balances
      users.create
      users.funds.request
      users.funds.status
      users.login
      users.password.change
      users.password.reset
      users.pricing
      users.update
      users.addresses.create
      users.addresses.delete
      users.addresses.info
      users.addresses.list
      users.addresses.default
      users.addresses.update
    ]
  end

  around do |example|
    Dir.mktmpdir do |directory|
      @directory = directory
      example.run
    end
  end

  it "catalogs every parity CLI route" do
    paths = Namecheap::CLI::Catalog::COMMANDS.map { |command| command.fetch("path").tr(" ", ".") }
    expect(paths).to include(*expected_commands)
  end

  it "previews registered nameserver writes without a request" do
    request = stub_request(:post, Namecheap::API::Base::SANDBOX)
    code, stdout, stderr = run_cli(
      "domains", "nameservers", "create",
      "example.com", "ns1.example.com", "192.0.2.10",
      "--dry-run", "--json"
    )

    expect(code).to eq(0), stderr
    expect(JSON.parse(stdout).dig("meta", "dry_run")).to be(true)
    expect(request).not_to have_been_requested
  end

  it "keeps transfer codes out of argv and dry-run output" do
    input = private_document("transfer.json", "epp_code" => "transfer-secret", "years" => 1)
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.users.getPricing", "ActionName" => "TRANSFER"))
      .to_return(body: price_xml)

    code, stdout, stderr = run_cli(
      "domains", "transfers", "create", "example.com",
      "--input", input, "--dry-run", "--json"
    )

    expect(code).to eq(0), stderr
    expect(stdout).not_to include("transfer-secret")
  end

  it "requires private permissions for password documents" do
    input = File.join(@directory, "password.json")
    File.write(input, JSON.generate("password" => "secret-password"))
    File.chmod(0o644, input)

    code, _stdout, stderr = run_cli("users", "login", input)

    expect(code).to eq(2)
    expect(stderr).to include("must not be accessible by group or others")
    expect(stderr).not_to include("secret-password")
  end

  it "posts passwords without rendering them" do
    input = private_document("password.json", "password" => "secret-password")
    request = stub_request(:post, Namecheap::API::Base::SANDBOX)
      .with(body: hash_including("Command" => "namecheap.users.login", "Password" => "secret-password"))
      .to_return(body: "<ApiResponse Status=\"OK\"><CommandResponse><UserLoginResult LoginSuccess=\"true\"/></CommandResponse></ApiResponse>")

    code, stdout, stderr = run_cli("users", "login", input, "--json")

    expect(code).to eq(0), stderr
    expect(stdout).not_to include("secret-password")
    expect(request).to have_been_requested.once
  end

  it "requires an expected price for unquotable privacy renewal" do
    code, _stdout, stderr = run_cli("domain-privacy", "renew", "10", "--years", "1", "--dry-run")

    expect(code).to eq(2)
    expect(stderr).to include("--expected-price is required")
  end

  it "previews address creation and SSL completion mutations without requests" do
    address = private_document(
      "address.json",
      {
        "address_name" => "primary",
        "default" => false,
        "address" => {
          "email_address" => "person@example.com",
          "first_name" => "Example",
          "last_name" => "Person",
          "address_1" => "1 Example Street",
          "city" => "Example City",
          "state_province" => "CA",
          "state_province_choice" => "P",
          "postal_code" => "90210",
          "country" => "US",
          "phone" => "+1.5555550100"
        }
      }
    )
    request = stub_request(:any, Namecheap::API::Base::SANDBOX)

    code, stdout, stderr = run_cli("users", "addresses", "create", address, "--dry-run", "--json")
    expect(code).to eq(0), stderr
    expect(JSON.parse(stdout).dig("meta", "dry_run")).to be(true)

    code, stdout, stderr = run_cli(
      "ssl", "revoke", "10", "--type", "Standard SSL SSLcom", "--dry-run", "--json"
    )
    expect(code).to eq(0), stderr
    expect(JSON.parse(stdout).dig("meta", "dry_run")).to be(true)
    expect(request).not_to have_been_requested
  end

  it "requires expected pricing for additional SSL SANs" do
    code, _stdout, stderr = run_cli("ssl", "sans", "purchase", "10", "--count", "2", "--dry-run")

    expect(code).to eq(2)
    expect(stderr).to include("--expected-price is required")
  end

  def price_xml
    <<~XML
      <ApiResponse Status="OK"><CommandResponse><UserGetPricingResult>
        <ProductType Name="DOMAIN"><ProductCategory Name="TRANSFER"><Product Name="COM">
          <Price Duration="1" YourPrice="12.00" Currency="USD"/>
        </Product></ProductCategory></ProductType>
      </UserGetPricingResult></CommandResponse></ApiResponse>
    XML
  end
end
