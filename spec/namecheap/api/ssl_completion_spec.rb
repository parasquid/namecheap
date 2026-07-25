require "spec_helper"

RSpec.describe "Namecheap SSL completion commands" do
  let(:credentials) do
    {
      "ApiUser" => "api-user",
      "ApiKey" => "api-key",
      "UserName" => "account-user",
      "ClientIp" => "192.0.2.1"
    }
  end
  let(:ssl) do
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    ).ssl
  end
  let(:response_body) do
    "<ApiResponse Status=\"OK\"><CommandResponse><SSLResult IsSuccess=\"true\"/></CommandResponse></ApiResponse>"
  end

  def verify(command, params)
    request = stub_request(:post, Namecheap::API::Base::SANDBOX)
      .with(body: credentials.merge(params).merge("Command" => command).transform_values(&:to_s))
      .to_return(body: response_body)
    expect(yield).to be_a(Namecheap::API::Response)
    expect(request).to have_been_requested.once
  end

  it "purchases SANs, revokes certificates, and edits both DCV modes" do
    verify("namecheap.ssl.purchasemoresans", "CertificateID" => 10, "NumberOfSANSToAdd" => 2) do
      ssl.purchase_more_sans(certificate_id: 10, count: 2)
    end
    verify("namecheap.ssl.revokecertificate", "CertificateID" => 10, "CertificateType" => "Standard SSL SSLcom") do
      ssl.revoke_certificate(certificate_id: 10, certificate_type: "Standard SSL SSLcom")
    end
    verify("namecheap.ssl.editDCVMethod", "CertificateID" => 10, "DCVMethod" => "CNAME_CSR_HASH") do
      ssl.edit_dcv_method(certificate_id: 10, dcv_method: "CNAME_CSR_HASH")
    end
    verify(
      "namecheap.ssl.editDCVMethod",
      "CertificateID" => 10,
      "DNSNames" => "example.com,www.example.com",
      "DCVMethods" => "CNAME_CSR_HASH,HTTP_CSR_HASH"
    ) do
      ssl.edit_dcv_method(
        certificate_id: 10,
        domain_methods: {
          "example.com" => "CNAME_CSR_HASH",
          "www.example.com" => "HTTP_CSR_HASH"
        }
      )
    end
  end

  it "validates SAN counts and DCV modes" do
    expect { ssl.purchase_more_sans(certificate_id: 10, count: 0) }
      .to raise_error(ArgumentError, "count must be between 1 and 99")
    expect { ssl.edit_dcv_method(certificate_id: 10) }
      .to raise_error(ArgumentError, /exactly one/)
    expect do
      ssl.edit_dcv_method(certificate_id: 10, dcv_method: "HTTP_CSR_HASH", domain_methods: {"example.com" => "CNAME_CSR_HASH"})
    end.to raise_error(ArgumentError, /exactly one/)
  end
end
