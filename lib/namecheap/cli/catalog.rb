require "namecheap/version"

module Namecheap
  module CLI
    module Catalog
      def self.schemas_for(path)
        case path
        when "domains register" then ["contacts", "params"]
        when "dns records apply" then ["zone"]
        when "config contacts add" then ["contact"]
        else []
        end
      end

      def self.examples_for(path)
        case path
        when "domains register"
          ["namecheap domains register example.com --contact default --years 1 --dry-run"]
        when "dns records apply"
          ["namecheap dns records apply example.com zone.yml --dry-run"]
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
        options += ["--type TYPE", "--host HOST", "--value VALUE", "--mx-pref NUMBER", "--ttl SECONDS", "--email-type TYPE"] if path == "dns records add"
        options += ["--type TYPE", "--host HOST", "--value VALUE", "--email-type TYPE"] if path == "dns records remove"
        options += ["--email-type TYPE"] if path == "dns records apply"
        options += ["--contacts-file FILE"] if path == "config contacts add"
        options
      end

      COMMAND_MUTATIONS = [
        "config profiles add",
        "config profiles use",
        "config profiles remove",
        "config contacts add",
        "config contacts remove",
        "domains lock set",
        "domains register",
        "domains renew",
        "dns nameservers default",
        "dns nameservers custom",
        "dns records add",
        "dns records remove",
        "dns records apply"
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
        ["domains tlds", "List supported top-level domains.", "", false, false],
        ["domains price", "Quote registration or renewal pricing.", "DOMAIN", false, false],
        ["domains lock status", "Show registrar-lock status.", "DOMAIN", false, false],
        ["domains lock set", "Enable or disable registrar lock.", "DOMAIN STATE", true, false],
        ["domains register", "Register an available domain.", "DOMAIN", true, true],
        ["domains renew", "Renew a domain.", "DOMAIN", true, true],
        ["dns nameservers list", "List nameservers for a domain.", "DOMAIN", false, false],
        ["dns nameservers default", "Use Namecheap default DNS.", "DOMAIN", true, false],
        ["dns nameservers custom", "Set custom nameservers.", "DOMAIN NAMESERVER...", true, false],
        ["dns records list", "List host records for a domain.", "DOMAIN", false, false],
        ["dns records add", "Safely add one host record.", "DOMAIN", true, false],
        ["dns records remove", "Safely remove one host record.", "DOMAIN", true, false],
        ["dns records apply", "Safely replace host records from YAML or JSON.", "DOMAIN [FILE]", true, false],
        ["dns forwarding list", "List email forwarding rules.", "DOMAIN", false, false]
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
