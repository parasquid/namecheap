require "spec_helper"
require "json"
require "stringio"
require "tempfile"
load File.expand_path("../../script/cli_sandbox_smoke", __dir__)

RSpec.describe CliSandboxSmoke do
  let(:environment_file) do
    Tempfile.new("namecheap-cli-staging").tap do |file|
      file.write("NAMECHEAP_ENVIRONMENT=sandbox\n")
      file.close
    end
  end
  let(:output) { StringIO.new }
  let(:cli) do
    Class.new do
      class << self
        attr_reader :calls

        def run(arguments, stdout:, **)
          @calls ||= []
          @calls << arguments
          stdout.puts(JSON.generate(response(arguments)))
          0
        end

        private

        def response(arguments)
          case arguments.take(3)
          when ["help", "domains", "register"]
            {"path" => "domains register", "paid" => true}
          when ["domains", "list", "--json"]
            {"data" => {"domain" => {"name" => "existing.example"}}, "meta" => {}}
          when ["domains", "check", arguments[2]]
            {"data" => {"domain" => arguments[2]}, "meta" => {}}
          when ["domains", "price", arguments[2]]
            {"data" => {"price" => "12.34", "currency" => "USD"}, "meta" => {}}
          when ["dns", "records", "list"]
            {"data" => {"domain" => arguments[3], "host" => []}, "meta" => {}}
          else
            {"data" => {"after" => [{"host_name" => "cli-smoke-preview"}]}, "meta" => {"dry_run" => true}}
          end
        end
      end
    end
  end

  after do
    environment_file.unlink
  end

  it "covers help, domain reads, pricing, DNS reads, and a DNS dry-run" do
    described_class.new(env_file: environment_file.path, output: output, cli: cli).run

    expect(output.string).to include("CLI sandbox smoke checks passed.")
    expect(cli.calls).to include(
      array_including("domains", "price"),
      array_including("dns", "records", "list"),
      array_including("dns", "records", "add", "--dry-run")
    )
  end

  it "refuses a production environment file" do
    environment_file.open
    environment_file.truncate(0)
    environment_file.write("NAMECHEAP_ENVIRONMENT=production\n")
    environment_file.close

    expect do
      described_class.new(env_file: environment_file.path, cli: cli)
    end.to raise_error(RuntimeError, /refuses/)
  end
end
