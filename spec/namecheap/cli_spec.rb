require "spec_helper"
require "namecheap/cli"
require "json"
require "stringio"
require "tmpdir"

RSpec.describe Namecheap::CLI do
  def run_cli(*arguments, env: {})
    stdout = StringIO.new
    stderr = StringIO.new
    stdin = StringIO.new
    code = described_class.run(
      arguments,
      stdout: stdout,
      stderr: stderr,
      stdin: stdin,
      env: {"HOME" => @directory}.merge(env)
    )
    [code, stdout.string, stderr.string]
  end

  def credentials
    {
      "NAMECHEAP_API_USER" => "api-user",
      "NAMECHEAP_API_KEY" => "api-key",
      "NAMECHEAP_USERNAME" => "account-user",
      "NAMECHEAP_CLIENT_IP" => "192.0.2.1",
      "NAMECHEAP_ENVIRONMENT" => "sandbox"
    }
  end

  around do |example|
    Dir.mktmpdir do |directory|
      @directory = directory
      example.run
    end
  end

  it "provides credential-free machine-readable help" do
    code, stdout, stderr = run_cli("help", "domains", "register", "--json")
    help = JSON.parse(stdout)

    expect(code).to eq(0), stderr
    expect(stderr).to be_empty
    expect(help).to include("path" => "domains register", "mutates" => true, "paid" => true)
    expect(help["input_schemas"]).to contain_exactly("contacts", "params")
  end

  it "suggests the nearest command for invalid syntax" do
    code, _stdout, stderr = run_cli("domains", "chek")

    expect(code).to eq(2)
    expect(stderr).to include("Try: namecheap help domains check")
  end

  it "uses env-file credentials for an API read and emits JSON" do
    env_file = File.join(@directory, "sandbox.env")
    File.write(
      env_file,
      <<~ENV
        NAMECHEAP_API_USER=api-user
        NAMECHEAP_API_KEY=api-key
        NAMECHEAP_USERNAME=account-user
        NAMECHEAP_CLIENT_IP=192.0.2.1
        NAMECHEAP_ENVIRONMENT=sandbox
      ENV
    )
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.domains.check", "DomainList" => "example.com"))
      .to_return(
        body: <<~XML
          <ApiResponse Status="OK">
            <CommandResponse>
              <DomainCheckResult Domain="example.com" Available="true"/>
            </CommandResponse>
          </ApiResponse>
        XML
      )

    code, stdout, stderr = run_cli("domains", "check", "example.com", "--env-file", env_file, "--json")

    expect(code).to eq(0), stderr
    expect(stderr).to be_empty
    response = JSON.parse(stdout)
    expect(response["data"]).to include("domain" => "example.com", "available" => true)
    expect(response["meta"]).to include("environment" => "sandbox")
  end

  it "saves config with private permissions and redacts API keys" do
    env = {
      "NAMECHEAP_API_USER" => "api-user",
      "NAMECHEAP_API_KEY" => "api-key",
      "NAMECHEAP_CLIENT_IP" => "192.0.2.1"
    }
    code, = run_cli("config", "profiles", "add", "sandbox", env: env)
    config = File.join(@directory, ".config", "namecheap", "config.yml")

    expect(code).to eq(0)
    expect(File.stat(config).mode & 0o777).to eq(0o600)
    expect(File.stat(File.dirname(config)).mode & 0o777).to eq(0o700)

    code, stdout, = run_cli("config", "profiles", "show", "sandbox")
    expect(code).to eq(0)
    expect(stdout).to include("[redacted]")
    expect(stdout).not_to include("api-key")
  end

  it "redacts complete profiles in every output format" do
    config = File.join(@directory, "config.yml")
    File.write(
      config,
      <<~YAML
        version: 1
        profiles:
          sandbox:
            api_user: api-user
            api_key: profile-api-key-value
            password_policy: visible-policy
            environment: sandbox
      YAML
    )

    [[], ["--json"], ["--raw"]].each do |format|
      code, stdout, stderr = run_cli("config", "profiles", "show", "sandbox", "--config", config, *format)

      expect(code).to eq(0), stderr
      expect(stdout).to include("[redacted]", "visible-policy")
      expect(stdout).not_to include("profile-api-key-value")
    end
  end

  it "returns safe diagnostics for malformed sensitive and credential inputs" do
    password_file = File.join(@directory, "password.json")
    File.write(password_file, %({"password": password-value-that-must-not-leak}))
    File.chmod(0o600, password_file)

    code, stdout, stderr = run_cli("users", "login", password_file, env: credentials)

    expect(code).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include("invalid password input", "expected valid JSON")
    expect(stderr).not_to include("password-value-that-must-not-leak")

    env_file = File.join(@directory, "credentials.env")
    File.write(env_file, "NAMECHEAP_API_KEY credential-value-that-must-not-leak\n")

    code, stdout, stderr = run_cli("domains", "check", "example.com", "--env-file", env_file)

    expect(code).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include("line 1 must be KEY=VALUE")
    expect(stderr).not_to include("credential-value-that-must-not-leak")
  end

  it "never repeats transfer, reset, token, or authorization values from malformed documents" do
    cases = [
      [
        "transfer.json",
        %({"epp_code": epp-value-that-must-not-leak}),
        ->(path) { ["domains", "transfers", "create", "example.com", "--input", path] }
      ],
      [
        "password-change.json",
        %({"new_password": "new", "reset_code": reset-value-that-must-not-leak}),
        ->(path) { ["users", "password", "change", path] }
      ],
      [
        "token.json",
        %({"token": token-value-that-must-not-leak}),
        ->(path) { ["domains", "check", "example.com", "--params", path] }
      ],
      [
        "authorization.json",
        %({"authorization_code": authorization-value-that-must-not-leak}),
        ->(path) { ["domains", "check", "example.com", "--params", path] }
      ]
    ]

    cases.each do |name, content, arguments|
      path = File.join(@directory, name)
      File.write(path, content)
      File.chmod(0o600, path)

      code, stdout, stderr = run_cli(*arguments.call(path), env: credentials)

      expect(code).to eq(2)
      expect(stdout).to be_empty
      expect(stderr).to include("expected valid JSON")
      expect(stderr).not_to include("value-that-must-not-leak")
    end
  end

  it "returns a safe diagnostic for malformed configuration" do
    config = File.join(@directory, "config.yml")
    File.write(config, "profiles: [api-key-value-that-must-not-leak\n")

    code, stdout, stderr = run_cli("config", "profiles", "list", "--config", config)

    expect(code).to eq(2)
    expect(stdout).to be_empty
    expect(stderr).to include("expected valid YAML")
    expect(stderr).not_to include("api-key-value-that-must-not-leak")
  end

  it "redacts returned tokens and copies embedded in URLs in every output format" do
    response_xml = <<~XML
      <ApiResponse Status="OK">
        <CommandResponse>
          <CreateAddFundsRequestResult
            TokenID="returned-token-value-123"
            RedirectURL="https://example.test/pay?tokenid=returned-token-value-123" />
        </CommandResponse>
      </ApiResponse>
    XML
    stub_request(:post, Namecheap::API::Base::SANDBOX).to_return(body: response_xml)

    [[], ["--json"], ["--raw"]].each do |format|
      code, stdout, stderr = run_cli(
        "users", "funds", "request", "reseller-user",
        "--amount", "40",
        "--return-url", "https://example.test/return",
        "--yes",
        *format,
        env: credentials
      )

      expect(code).to eq(0), stderr
      expect(stdout).to include("[redacted]")
      expect(stdout).not_to include("returned-token-value-123")
    end
  end

  it "scrubs positional tokens from API errors" do
    token = "submitted-token-value-123"
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.users.getAddFundsStatus", "TokenId" => token))
      .to_return(
        body: <<~XML
          <ApiResponse Status="ERROR">
            <Errors><Error Number="2012342">TokenID #{token} did not match</Error></Errors>
            <CommandResponse />
          </ApiResponse>
        XML
      )

    code, stdout, stderr = run_cli("users", "funds", "status", token, env: credentials)

    expect(code).to eq(1)
    expect(stdout).to be_empty
    expect(stderr).to include("TokenID [redacted] did not match")
    expect(stderr).not_to include(token)
  end

  it "keeps trusted placeholders in generated examples" do
    code, stdout, stderr = run_cli("help", "users", "login", "--example", "password")

    expect(code).to eq(0), stderr
    expect(stdout).to include("replace-with-password")
  end

  it "quotes exact domain pricing without making a purchase" do
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.users.getPricing", "ActionName" => "REGISTER", "ProductName" => "COM"))
      .to_return(
        body: <<~XML
          <ApiResponse Status="OK">
            <CommandResponse>
              <UserGetPricingResult>
                <ProductType Name="DOMAIN">
                  <ProductCategory Name="DOMAINS">
                    <Product Name="COM">
                      <Price Duration="1" DurationType="YEAR" Price="12.98" RegularPrice="14.98" YourPrice="12.98" Currency="USD"/>
                    </Product>
                  </ProductCategory>
                </ProductType>
              </UserGetPricingResult>
            </CommandResponse>
          </ApiResponse>
        XML
      )

    code, stdout, stderr = run_cli("domains", "price", "example.com", "--json", env: credentials)
    response = JSON.parse(stdout)

    expect(code).to eq(0), stderr
    expect(response["data"]).to include("domain" => "example.com", "price" => "12.98", "currency" => "USD")
  end

  it "previews a DNS addition without submitting the replacement zone" do
    get_hosts = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.domains.dns.getHosts"))
      .to_return(
        body: <<~XML
          <ApiResponse Status="OK">
            <CommandResponse>
              <DomainDNSGetHostsResult Domain="example.com" EmailType="MXE">
                <host HostId="1" Name="@" Type="A" Address="192.0.2.10" TTL="1800"/>
              </DomainDNSGetHostsResult>
            </CommandResponse>
          </ApiResponse>
        XML
      )
    set_hosts = stub_request(:post, Namecheap::API::Base::SANDBOX)

    code, stdout, stderr = run_cli(
      "dns", "records", "add", "example.com",
      "--type", "TXT", "--host", "@", "--value", "hello", "--dry-run", "--json",
      env: credentials
    )
    response = JSON.parse(stdout)

    expect(code).to eq(0), stderr
    expect(response["meta"]).to include("dry_run" => true)
    expect(response["data"]["after"].length).to eq(2)
    expect(get_hosts).to have_been_requested.once
    expect(set_hosts).not_to have_been_requested
  end

  it "rechecks drift, replaces the full zone, and verifies a DNS addition" do
    one_record = <<~XML
      <ApiResponse Status="OK"><CommandResponse>
        <DomainDNSGetHostsResult Domain="example.com" EmailType="MX">
          <host Name="@" Type="MX" Address="mail.example.com." MXPref="10" TTL="1800"/>
        </DomainDNSGetHostsResult>
      </CommandResponse></ApiResponse>
    XML
    two_records = <<~XML
      <ApiResponse Status="OK"><CommandResponse>
        <DomainDNSGetHostsResult Domain="example.com" EmailType="MX">
          <host Name="@" Type="MX" Address="mail.example.com." MXPref="10" TTL="1800"/>
          <host Name="www" Type="A" Address="192.0.2.20" MXPref="10" TTL="300"/>
        </DomainDNSGetHostsResult>
      </CommandResponse></ApiResponse>
    XML
    get_hosts = stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.domains.dns.getHosts"))
      .to_return({body: one_record}, {body: one_record}, {body: two_records})
    set_hosts = stub_request(:post, Namecheap::API::Base::SANDBOX)
      .with do |request|
        values = URI.decode_www_form(request.body).to_h
        values.slice("Command", "RecordType1", "MXPref1", "RecordType2", "HostName2") == {
          "Command" => "namecheap.domains.dns.setHosts",
          "RecordType1" => "MX",
          "MXPref1" => "10",
          "RecordType2" => "A",
          "HostName2" => "www"
        }
      end
      .to_return(body: "<ApiResponse Status=\"OK\"><CommandResponse><DomainDNSSetHostsResult IsSuccess=\"true\"/></CommandResponse></ApiResponse>")

    code, stdout, stderr = run_cli(
      "dns", "records", "add", "example.com",
      "--type", "A", "--host", "www", "--value", "192.0.2.20", "--ttl", "300", "--yes", "--json",
      env: credentials
    )

    expect(code).to eq(0), stderr
    expect(JSON.parse(stdout)["data"]["records"].length).to eq(2)
    expect(get_hosts).to have_been_requested.times(3)
    expect(set_hosts).to have_been_requested.once
  end
end
