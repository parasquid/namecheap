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
