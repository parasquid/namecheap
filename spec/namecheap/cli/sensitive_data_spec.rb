require "spec_helper"
require "namecheap/cli/sensitive_data"

RSpec.describe Namecheap::CLI::SensitiveData do
  subject(:sensitive_data) { described_class.new }

  it "matches canonical sensitive field names across upstream spellings" do
    value = {
      "ApiKey" => "api-key-value",
      "APIKey" => "alternate-api-key-value",
      "OldPassword" => "old-password-value",
      "NewUserPassword" => "new-password-value",
      "EPPCode" => "epp-code-value",
      "ResetCode" => "reset-code-value",
      "TokenID" => "token-value",
      "Authorization-Code" => "authorization-value"
    }

    expect(sensitive_data.redact(value).values.uniq).to eq(["[redacted]"])
  end

  it "redacts recursively without modifying the input" do
    value = {
      "items" => [
        {"password" => "password-value"},
        {"nested" => {"auth_code" => "authorization-value"}}
      ]
    }

    redacted = sensitive_data.redact(value)

    expect(redacted).to eq(
      "items" => [
        {"password" => "[redacted]"},
        {"nested" => {"auth_code" => "[redacted]"}}
      ]
    )
    expect(value.dig("items", 0, "password")).to eq("password-value")
  end

  it "scrubs discovered secrets from other string fields" do
    value = {
      "token_id" => "token-value-123",
      "redirect_url" => "https://example.test/pay?tokenid=token-value-123"
    }

    expect(sensitive_data.redact(value)).to eq(
      "token_id" => "[redacted]",
      "redirect_url" => "https://example.test/pay?tokenid=[redacted]"
    )
  end

  it "keeps unrelated fields visible" do
    value = {
      "password_policy" => "visible-password-policy",
      "api_keyboard" => "visible-api-keyboard",
      "epp_code_required" => true,
      "tokenized" => "visible-tokenized",
      "authorization_code_status" => "available",
      "secretary" => "Ada"
    }

    expect(sensitive_data.redact(value)).to eq(value)
  end

  it "redacts sensitive XML fields and repeated values" do
    xml = <<~XML
      <ApiResponse>
        <Result TokenID="token-value-123" RedirectURL="https://example.test/pay?tokenid=token-value-123">
          <Password>password-value</Password>
          <password_policy>visible</password_policy>
        </Result>
      </ApiResponse>
    XML

    redacted = sensitive_data.redact_xml(xml)

    expect(redacted).to include("TokenID='[redacted]'")
    expect(redacted).to include("tokenid=[redacted]")
    expect(redacted).to include("<Password>[redacted]</Password>")
    expect(redacted).to include("<password_policy>visible</password_policy>")
    expect(redacted).not_to include("token-value-123", "password-value")
  end

  it "preserves exact XML when no redaction is needed" do
    xml = "<Result Status=\"OK\" />\n"

    expect(sensitive_data.redact_xml(xml)).to equal(xml)
  end

  it "fails closed for malformed raw XML" do
    expect { sensitive_data.redact_xml("<Result TokenID=") }
      .to raise_error(described_class::UnsafeOutputError, /could not be safely inspected/)
  end
end
