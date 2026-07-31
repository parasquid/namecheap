require "spec_helper"
require "namecheap/cli/renderer"
require "json"
require "stringio"

RSpec.describe Namecheap::CLI::Renderer do
  def render(format, data, meta: {}, raw_xml: false)
    output = StringIO.new
    described_class.new(io: output, format: format).render(data, meta: meta, raw_xml: raw_xml)
    output.string
  end

  it "redacts human output" do
    output = render(:human, {"api_key" => "api-key-value", "secretary" => "Ada"})

    expect(output).to include("Api Key: [redacted]", "Secretary: Ada")
    expect(output).not_to include("api-key-value")
  end

  it "redacts JSON data and metadata through one boundary" do
    output = render(
      :json,
      {"token_id" => "token-value-123", "url" => "https://example.test/token-value-123"},
      meta: {"api_key" => "api-key-value"}
    )
    parsed = JSON.parse(output)

    expect(parsed).to eq(
      "data" => {
        "token_id" => "[redacted]",
        "url" => "https://example.test/[redacted]"
      },
      "meta" => {"api_key" => "[redacted]"}
    )
  end

  it "redacts structured raw output" do
    output = render(:raw, {"password" => "password-value", "password_policy" => "visible"})

    expect(output).to match(/"password"\s*=>\s*"\[redacted\]"/)
    expect(output).to match(/"password_policy"\s*=>\s*"visible"/)
    expect(output).not_to include("password-value")
  end

  it "sanitizes raw XML output" do
    output = render(
      :raw,
      "<Result TokenID=\"token-value-123\" URL=\"https://example.test/token-value-123\" />",
      raw_xml: true
    )

    expect(output).to include("TokenID='[redacted]'", "https://example.test/[redacted]")
    expect(output).not_to include("token-value-123")
  end
end
