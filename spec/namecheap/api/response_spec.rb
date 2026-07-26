require "spec_helper"

RSpec.describe Namecheap::API::Response do
  it "normalizes successful responses and preserves the raw XML" do
    xml = <<~XML
      <ApiResponse xmlns="http://api.namecheap.com/xml.response" Status="OK">
        <Warnings><Warning Number="1">Notice</Warning></Warnings>
        <RequestedCommand>namecheap.domains.getList</RequestedCommand>
        <CommandResponse>
          <DomainGetListResult>
            <Domain ID="12" Name="example.com" IsExpired="false" Price="12.50"/>
            <Domain ID="0013" Name="example.net" IsExpired="true"/>
          </DomainGetListResult>
          <Paging><TotalItems>2</TotalItems><CurrentPage>1</CurrentPage></Paging>
        </CommandResponse>
        <Server>API01</Server>
        <ExecutionTime>0.125</ExecutionTime>
      </ApiResponse>
    XML

    response = described_class.parse(xml, command: "namecheap.domains.getList")

    expect(response.status).to eq("OK")
    expect(response.requested_command).to eq("namecheap.domains.getList")
    expect(response.data[:domain]).to contain_exactly(
      {id: 12, name: "example.com", is_expired: false, price: "12.50"},
      {id: "0013", name: "example.net", is_expired: true}
    )
    expect(response.paging).to eq(total_items: 2, current_page: 1)
    expect(response.warnings).to eq([{code: "1", message: "Notice"}])
    expect(response.execution_time).to eq("0.125")
    expect(response.raw_body).to eq(xml)
    expect(response.to_h).not_to have_key(:raw_body)
  end

  it "raises a structured API error" do
    xml = <<~XML
      <ApiResponse Status="ERROR">
        <Errors><Error Number="2019166">Domain is invalid</Error></Errors>
      </ApiResponse>
    XML

    expect do
      described_class.parse(xml, command: "namecheap.domains.getInfo")
    end.to raise_error(Namecheap::API::ApiError) { |error|
      expect(error.command).to eq("namecheap.domains.getInfo")
      expect(error.errors).to eq([{code: "2019166", message: "Domain is invalid"}])
      expect(error.response.raw_body).to eq(xml)
    }
  end

  it "raises a parse error for malformed XML" do
    expect do
      described_class.parse("not xml", command: "namecheap.domains.getList")
    end.to raise_error(Namecheap::API::ParseError, /invalid XML response/)
  end

  it "raises a transport error for non-success HTTP responses" do
    client = Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    )
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.domains.getList"))
      .to_return(status: 503, body: "unavailable")

    expect { client.domains.get_list }
      .to raise_error(Namecheap::API::TransportError, "Namecheap returned HTTP 503") { |error|
        expect(error.http_status).to eq(503)
        expect(error.command).to eq("namecheap.domains.getList")
        expect(error.message).not_to include("ApiKey")
      }
  end

  it "raises a transport error for timeout failures" do
    client = Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    )
    stub_request(:get, Namecheap::API::Base::SANDBOX)
      .with(query: hash_including("Command" => "namecheap.domains.getList"))
      .to_raise(Faraday::TimeoutError.new("execution expired"))

    expect { client.domains.get_list }
      .to raise_error(Namecheap::API::TransportError, "Namecheap request failed: Faraday::TimeoutError") { |error|
        expect(error.command).to eq("namecheap.domains.getList")
        expect(error.message).not_to include("ApiKey")
      }
  end
end
