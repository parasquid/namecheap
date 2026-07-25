require "namecheap/version"

module Namecheap
  module CLI
    module Catalog
      def self.schemas_for(path)
        case path
        when "domains register" then ["contacts", "params"]
        when "domains contacts set" then ["contacts"]
        when "dns records apply" then ["zone"]
        when "dns forwarding set" then ["forwardings"]
        when "config contacts add" then ["contact"]
        when "domains transfers create" then ["transfer"]
        when "users create" then ["user"]
        when "users update" then ["user-profile"]
        when "users login" then ["password"]
        when "users password change" then ["password-change"]
        else []
        end
      end

      def self.examples_for(path)
        case path
        when "domains register"
          ["namecheap domains register example.com --contact default --years 1 --dry-run"]
        when "dns records apply"
          ["namecheap dns records apply example.com zone.yml --dry-run"]
        when "domains transfers create"
          ["namecheap domains transfers create example.com --input transfer.yml --dry-run"]
        when "ssl activate"
          ["namecheap ssl activate 12345 request.csr --dry-run"]
        when "users create"
          ["namecheap users create user.yml --dry-run"]
        else
          []
        end
      end

      def self.options_for(path)
        options = []
        options += ["--dry-run", "--yes"] if COMMAND_MUTATIONS.include?(path)
        options += ["--years YEARS", "--params FILE"] if ["domains register", "domains renew"].include?(path)
        options += ["--contact NAME", "--contacts-file FILE"] if path == "domains register"
        options += ["--action register|renew", "--years YEARS", "--params FILE"] if path == "domains price"
        options += ["--years YEARS", "--params FILE"] if path == "domains reactivate"
        options += ["--input FILE", "--params FILE"] if [
          "domains contacts set",
          "dns forwarding set",
          "domains transfers create",
          "users create",
          "users update",
          "users login",
          "users password change"
        ].include?(path)
        options += ["--years YEARS"] if path == "domains transfers create"
        options += ["--years YEARS", "--expected-price AMOUNT", "--currency CODE"] if path == "domain-privacy renew"
        options += ["--type TYPE", "--years YEARS", "--params FILE"] if ["ssl create", "ssl renew"].include?(path)
        options += ["--expected-price AMOUNT", "--currency CODE"] if path == "ssl create"
        options += ["--type TYPE", "--params FILE"] if ["ssl parse-csr", "ssl approver-emails", "ssl activate", "ssl reissue"].include?(path)
        options += ["--amount AMOUNT", "--return-url URL", "--params FILE"] if path == "users funds request"
        options += ["--params FILE"] if API_PARAM_COMMANDS.include?(path) && !options.include?("--params FILE")
        options += ["--type TYPE", "--host HOST", "--value VALUE", "--mx-pref NUMBER", "--ttl SECONDS", "--email-type TYPE"] if path == "dns records add"
        options += ["--type TYPE", "--host HOST", "--value VALUE", "--email-type TYPE"] if path == "dns records remove"
        options += ["--email-type TYPE"] if path == "dns records apply"
        options += ["--contacts-file FILE"] if path == "config contacts add"
        options.uniq
      end

      COMMAND_MUTATIONS = [
        "config profiles add",
        "config profiles use",
        "config profiles remove",
        "config contacts add",
        "config contacts remove",
        "domains lock set",
        "domains contacts set",
        "domains register",
        "domains renew",
        "domains reactivate",
        "domains nameservers create",
        "domains nameservers delete",
        "domains nameservers update",
        "domains transfers create",
        "domains transfers resubmit",
        "dns nameservers default",
        "dns nameservers custom",
        "dns records add",
        "dns records remove",
        "dns records apply",
        "dns forwarding set",
        "ssl create",
        "ssl activate",
        "ssl renew",
        "ssl reissue",
        "ssl resend approver",
        "ssl resend fulfillment",
        "users create",
        "users update",
        "users password change",
        "users password reset",
        "users funds request",
        "domain-privacy enable",
        "domain-privacy disable",
        "domain-privacy email rotate",
        "domain-privacy renew"
      ].freeze

      API_PARAM_COMMANDS = [
        "domains contacts set",
        "domains reactivate",
        "domains nameservers create",
        "domains nameservers delete",
        "domains nameservers info",
        "domains nameservers update",
        "domains transfers create",
        "domains transfers list",
        "domains transfers status",
        "domains transfers resubmit",
        "dns forwarding set",
        "ssl create",
        "ssl list",
        "ssl info",
        "ssl parse-csr",
        "ssl approver-emails",
        "ssl activate",
        "ssl renew",
        "ssl reissue",
        "ssl resend approver",
        "ssl resend fulfillment",
        "users pricing",
        "users balances",
        "users create",
        "users update",
        "users login",
        "users password change",
        "users password reset",
        "users funds request",
        "users funds status",
        "domain-privacy list",
        "domain-privacy enable",
        "domain-privacy disable",
        "domain-privacy email rotate",
        "domain-privacy renew"
      ].freeze

      COMMANDS = [
        ["config profiles add", "Save or replace a credential profile.", "NAME", true, false],
        ["config profiles list", "List configured profiles.", "", false, false],
        ["config profiles show", "Show a profile with its API key redacted.", "[NAME]", false, false],
        ["config profiles use", "Select the default profile.", "NAME", true, false],
        ["config profiles remove", "Remove a saved profile.", "NAME", true, false],
        ["config contacts add", "Save or replace a reusable contact.", "NAME", true, false],
        ["config contacts list", "List saved contacts.", "", false, false],
        ["config contacts show", "Show a saved contact.", "NAME", false, false],
        ["config contacts remove", "Remove a saved contact.", "NAME", true, false],
        ["domains list", "List domains in the account.", "", false, false],
        ["domains check", "Check whether domains are available.", "DOMAIN...", false, false],
        ["domains info", "Show details for a domain.", "DOMAIN", false, false],
        ["domains contacts", "Show contacts for a domain.", "DOMAIN", false, false],
        ["domains contacts set", "Replace contacts for a domain.", "DOMAIN [FILE]", true, false],
        ["domains tlds", "List supported top-level domains.", "", false, false],
        ["domains price", "Quote registration or renewal pricing.", "DOMAIN", false, false],
        ["domains lock status", "Show registrar-lock status.", "DOMAIN", false, false],
        ["domains lock set", "Enable or disable registrar lock.", "DOMAIN STATE", true, false],
        ["domains register", "Register an available domain.", "DOMAIN", true, true],
        ["domains renew", "Renew a domain.", "DOMAIN", true, true],
        ["domains reactivate", "Reactivate an expired domain.", "DOMAIN", true, true],
        ["domains nameservers create", "Create a registered nameserver.", "DOMAIN NAMESERVER IP", true, false],
        ["domains nameservers delete", "Delete a registered nameserver.", "DOMAIN NAMESERVER", true, false],
        ["domains nameservers info", "Show a registered nameserver.", "DOMAIN NAMESERVER", false, false],
        ["domains nameservers update", "Change a registered nameserver IP.", "DOMAIN NAMESERVER OLD_IP NEW_IP", true, false],
        ["domains transfers create", "Transfer a domain to Namecheap.", "DOMAIN", true, true],
        ["domains transfers list", "List domain transfers.", "", false, false],
        ["domains transfers status", "Show domain transfer status.", "TRANSFER_ID", false, false],
        ["domains transfers resubmit", "Resubmit a domain transfer.", "TRANSFER_ID", true, false],
        ["dns nameservers list", "List nameservers for a domain.", "DOMAIN", false, false],
        ["dns nameservers default", "Use Namecheap default DNS.", "DOMAIN", true, false],
        ["dns nameservers custom", "Set custom nameservers.", "DOMAIN NAMESERVER...", true, false],
        ["dns records list", "List host records for a domain.", "DOMAIN", false, false],
        ["dns records add", "Safely add one host record.", "DOMAIN", true, false],
        ["dns records remove", "Safely remove one host record.", "DOMAIN", true, false],
        ["dns records apply", "Safely replace host records from YAML or JSON.", "DOMAIN [FILE]", true, false],
        ["dns forwarding list", "List email forwarding rules.", "DOMAIN", false, false],
        ["dns forwarding set", "Replace email forwarding rules.", "DOMAIN [FILE]", true, false],
        ["ssl list", "List SSL certificates.", "", false, false],
        ["ssl info", "Show SSL certificate information.", "CERTIFICATE_ID", false, false],
        ["ssl create", "Purchase an SSL certificate.", "", true, true],
        ["ssl parse-csr", "Parse a certificate signing request.", "CSR_FILE", false, false],
        ["ssl approver-emails", "List SSL approver emails.", "DOMAIN", false, false],
        ["ssl activate", "Activate an SSL certificate.", "CERTIFICATE_ID CSR_FILE", true, false],
        ["ssl renew", "Renew an SSL certificate.", "CERTIFICATE_ID", true, true],
        ["ssl reissue", "Reissue an SSL certificate.", "CERTIFICATE_ID CSR_FILE", true, false],
        ["ssl resend approver", "Resend SSL approval or retry DCV.", "CERTIFICATE_ID", true, false],
        ["ssl resend fulfillment", "Resend the SSL fulfillment email.", "CERTIFICATE_ID", true, false],
        ["users pricing", "Get generic product pricing.", "PRODUCT_TYPE", false, false],
        ["users balances", "Show account balances.", "", false, false],
        ["users create", "Create a reseller user.", "[FILE]", true, false],
        ["users update", "Update the selected reseller user.", "[FILE]", true, false],
        ["users login", "Validate the selected reseller user.", "[FILE]", false, false],
        ["users password change", "Change a reseller user password.", "[FILE]", true, false],
        ["users password reset", "Send a reseller password reset email.", "FIND_BY VALUE", true, false],
        ["users funds request", "Create an add-funds redirect.", "USER_NAME", true, false],
        ["users funds status", "Show add-funds request status.", "TOKEN_ID", false, false],
        ["domain-privacy list", "List domain privacy subscriptions.", "", false, false],
        ["domain-privacy enable", "Enable a privacy subscription.", "ID FORWARDED_EMAIL", true, false],
        ["domain-privacy disable", "Disable a privacy subscription.", "ID", true, false],
        ["domain-privacy email rotate", "Rotate a privacy email address.", "ID", true, false],
        ["domain-privacy renew", "Renew a privacy subscription.", "ID", true, true]
      ].map do |path, summary, args, mutates, paid|
        {
          "path" => path,
          "summary" => summary,
          "usage" => ["namecheap", path, args].reject(&:empty?).join(" "),
          "args" => args.split,
          "options" => options_for(path),
          "input_schemas" => schemas_for(path),
          "mutates" => mutates,
          "paid" => paid,
          "examples" => examples_for(path),
          "exit_codes" => {"0" => "success", "1" => "API operation failed", "2" => "invalid usage or configuration", "3" => "declined", "130" => "interrupted"}
        }
      end.freeze

      GLOBAL_OPTIONS = [
        {"name" => "--profile NAME", "description" => "Use a named profile."},
        {"name" => "--env-file PATH", "description" => "Load credentials from an env file."},
        {"name" => "--environment NAME", "description" => "Select sandbox or production."},
        {"name" => "--config PATH", "description" => "Use an alternate config file."},
        {"name" => "--json", "description" => "Emit a stable JSON envelope."},
        {"name" => "--raw", "description" => "Emit the raw Namecheap XML response."}
      ].freeze

      def self.manifest
        {
          "schema_version" => 1,
          "cli_version" => Namecheap::VERSION,
          "global_options" => GLOBAL_OPTIONS,
          "commands" => COMMANDS
        }
      end

      def self.find(path)
        COMMANDS.find { |command| command["path"] == Array(path).join(" ") }
      end

      def self.children(path)
        prefix = Array(path).join(" ")
        COMMANDS.select { |command| prefix.empty? || command["path"].start_with?("#{prefix} ") }
      end
    end
  end
end
