require "json"
require "bigdecimal"
require "thor"
require "yaml"
require "namecheap"
require "namecheap/cli/catalog"
require "namecheap/cli/config_store"
require "namecheap/cli/env_file"
require "namecheap/cli/error"
require "namecheap/cli/renderer"
require "namecheap/cli/xml"

module Namecheap
  module CLI
    class Runner
      CREDENTIAL_ENV = {
        api_user: "NAMECHEAP_API_USER",
        api_key: "NAMECHEAP_API_KEY",
        user_name: "NAMECHEAP_USERNAME",
        client_ip: "NAMECHEAP_CLIENT_IP",
        environment: "NAMECHEAP_ENVIRONMENT"
      }.freeze
      VALUE_OPTIONS = %w[
        --profile --env-file --environment --config --format --example --contact --contacts-file
        --params --years --action --type --host --value --mx-pref --ttl --email-type
      ].freeze
      BOOLEAN_OPTIONS = %w[--help --json --raw --yes --dry-run].freeze

      def initialize(stdout:, stderr:, stdin:, env:)
        @stdout = stdout
        @stderr = stderr
        @stdin = stdin
        @env = env
        @shell = Thor::Shell::Basic.new
      end

      def run(argv)
        @options, words = parse_options(Array(argv).dup)
        return help(words) if words.empty? || words.first == "help" || help_requested?(words)

        command, arguments = resolve(words)
        raise unknown_command(words) unless command

        dispatch(command["path"], arguments)
        0
      rescue Error => error
        @stderr.puts("Error: #{error.message}")
        error.exit_code
      rescue Interrupt
        @stderr.puts("Interrupted")
        130
      rescue ArgumentError => error
        @stderr.puts("Error: #{error.message}")
        2
      end

      private

      def parse_options(argv)
        options = {}
        words = []
        until argv.empty?
          token = argv.shift
          if token.start_with?("--") && token.include?("=")
            name, value = token.split("=", 2)
            validate_option!(name)
            options[name] = value
          elsif VALUE_OPTIONS.include?(token)
            raise Error, "#{token} requires a value" if argv.empty?
            options[token] = argv.shift
          elsif BOOLEAN_OPTIONS.include?(token)
            options[token] = true
          elsif token.start_with?("--")
            raise unknown_option(token)
          else
            words << token
          end
        end
        [options, words]
      end

      def validate_option!(name)
        return if VALUE_OPTIONS.include?(name) || BOOLEAN_OPTIONS.include?(name)

        raise unknown_option(name)
      end

      def help_requested?(words)
        return false unless @options.delete("--help") || words.last == "--help"

        words.pop if words.last == "--help"
        true
      end

      def resolve(words)
        Catalog::COMMANDS.sort_by { |entry| -entry["path"].split.length }.each do |entry|
          segments = entry["path"].split
          return [entry, words.drop(segments.length)] if words.take(segments.length) == segments
        end
        nil
      end

      def help(path)
        path = path.drop(1) if path.first == "help"
        if @options["--json"]
          entry = Catalog.find(path)
          payload = entry || (path.empty? ? Catalog.manifest : {"path" => path.join(" "), "commands" => Catalog.children(path)})
          @stdout.puts(JSON.pretty_generate(payload))
          return 0
        end

        if (example = @options["--example"])
          return print_example(path, example)
        end

        entry = Catalog.find(path)
        if entry
          @stdout.puts(entry["usage"])
          @stdout.puts
          @stdout.puts(entry["summary"])
          @stdout.puts
          @stdout.puts("Mutates: #{entry["mutates"] ? "yes" : "no"}")
          @stdout.puts("Paid: #{entry["paid"] ? "yes" : "no"}")
          if entry["options"].any?
            @stdout.puts
            @stdout.puts("Options:")
            entry["options"].each { |option| @stdout.puts("  #{option}") }
          end
          @stdout.puts("Examples:")
          entry["examples"].each { |example_line| @stdout.puts("  #{example_line}") }
        else
          @stdout.puts(path.empty? ? "Usage: namecheap COMMAND [OPTIONS]" : "Usage: namecheap #{path.join(" ")} COMMAND [OPTIONS]")
          @stdout.puts
          Catalog.children(path).each { |child| @stdout.puts("  %-34s %s" % [child["path"], child["summary"]]) }
          if path.empty?
            @stdout.puts
            @stdout.puts("Global options:")
            Catalog::GLOBAL_OPTIONS.each { |option| @stdout.puts("  %-22s %s" % [option["name"], option["description"]]) }
            @stdout.puts
            @stdout.puts("Machine-readable help: namecheap help --json")
          end
        end
        0
      end

      def print_example(path, name)
        content = case [path.join(" "), name]
        when ["domains register", "contacts"], ["config contacts add", "contact"]
          {"first_name" => "Ada", "last_name" => "Lovelace", "address_1" => "1 Example Street", "city" => "London", "state_province" => "London", "postal_code" => "SW1A 1AA", "country" => "GB", "phone" => "+44.1234567890", "email_address" => "ada@example.test"}
        when ["domains register", "params"]
          {"ExtendedAttributeName" => "value"}
        when ["dns records apply", "zone"]
          {"email_type" => "MXE", "records" => [{"host_name" => "@", "record_type" => "A", "address" => "192.0.2.10", "ttl" => 1800}]}
        else
          raise Error, "unknown example #{name.inspect}; run namecheap help #{path.join(" ")} --json"
        end
        format = @options["--format"] || "yaml"
        raise Error, "--format must be yaml or json" unless %w[yaml json].include?(format)

        @stdout.write((format == "json") ? JSON.pretty_generate(content) + "\n" : YAML.dump(content))
        0
      end

      def dispatch(path, arguments)
        case path
        when /\Aconfig profiles / then profile_command(path.split.last, arguments)
        when /\Aconfig contacts / then contact_command(path.split.last, arguments)
        when "domains list" then api_read(arguments) { |api| api.domains.get_list(params: api_params) }
        when "domains check"
          require_args!(arguments, 1)
          render_response(client.domains.check(domain_names: arguments, params: api_params))
        when "domains info" then domain_read(arguments) { |api, domain| api.domains.get_info(domain_name: domain, params: api_params) }
        when "domains contacts" then domain_read(arguments) { |api, domain| api.domains.get_contacts(domain_name: domain, params: api_params) }
        when "domains tlds" then api_read(arguments) { |api| api.domains.get_tld_list(params: api_params) }
        when "domains price" then price(arguments)
        when "domains lock status" then domain_read(arguments) { |api, domain| api.domains.get_registrar_lock(domain_name: domain, params: api_params) }
        when "domains lock set" then set_lock(arguments)
        when "domains register" then register(arguments)
        when "domains renew" then renew(arguments)
        when "dns nameservers list" then dns_read(arguments) { |dns, sld, tld| dns.get_list(sld: sld, tld: tld, params: api_params) }
        when "dns nameservers default" then dns_write(arguments, "Use Namecheap default DNS") { |dns, sld, tld| dns.set_default(sld: sld, tld: tld, params: api_params) }
        when "dns nameservers custom" then custom_nameservers(arguments)
        when "dns records list" then dns_read(arguments) { |dns, sld, tld| dns.get_hosts(sld: sld, tld: tld, params: api_params) }
        when "dns records add", "dns records remove", "dns records apply" then dns_records(path.split.last, arguments)
        when "dns forwarding list" then domain_read(arguments) { |api, domain| api.domains.dns.get_email_forwarding(domain_name: domain, params: api_params) }
        else raise Error, "command is not implemented: #{path}"
        end
      end

      def config_path
        @options["--config"] || File.join(@env["XDG_CONFIG_HOME"] || File.join(@env.fetch("HOME"), ".config"), "namecheap", "config.yml")
      end

      def store
        @store ||= ConfigStore.new(config_path)
      end

      def profile_command(action, arguments)
        case action
        when "list"
          require_args!(arguments, 0, exact: true)
          render(store.profiles.keys.sort.map { |name| {"name" => name, "default" => store.data["default_profile"] == name} })
        when "show"
          name = arguments.first || store.data["default_profile"] || raise(Error, "no default profile is selected")
          profile = store.profiles[name] || raise(Error, "profile not found: #{name}")
          render(profile.merge("name" => name, "api_key" => profile["api_key"] ? "[redacted]" : nil))
        when "add"
          name = one_arg!(arguments)
          values = credentials_from_environment(@env)
          values["api_key"] ||= prompt_secret("API key")
          %w[api_user api_key client_ip].each { |key| raise Error, "#{CREDENTIAL_ENV[key.to_sym]} must be set" if blank?(values[key]) }
          values["user_name"] ||= values["api_user"]
          values["environment"] ||= "sandbox"
          validate_environment!(values["environment"])
          return if dry_run!({"operation" => "save profile", "profile" => name, "environment" => values["environment"]})
          store.profiles[name] = values
          store.data["default_profile"] ||= name
          store.save!
          render({"saved" => name})
        when "use"
          name = one_arg!(arguments)
          raise Error, "profile not found: #{name}" unless store.profiles.key?(name)
          return if dry_run!({"operation" => "select default profile", "profile" => name})
          store.data["default_profile"] = name
          store.save!
          render({"default_profile" => name})
        when "remove"
          name = one_arg!(arguments)
          raise Error, "profile not found: #{name}" unless store.profiles.key?(name)
          return if dry_run!({"operation" => "remove profile", "profile" => name})
          confirm!("Remove profile #{name}?")
          store.profiles.delete(name)
          store.data.delete("default_profile") if store.data["default_profile"] == name
          store.save!
          render({"removed" => name})
        end
      end

      def contact_command(action, arguments)
        case action
        when "list"
          require_args!(arguments, 0, exact: true)
          render(store.contacts.keys.sort.map { |name| {"name" => name} })
        when "show"
          name = one_arg!(arguments)
          render(store.contacts[name] || raise(Error, "contact not found: #{name}"))
        when "add"
          name = one_arg!(arguments)
          contact = load_document(@options["--contacts-file"] || "-")
          validate_contact!(contact)
          return if dry_run!({"operation" => "save contact", "contact" => name})
          store.contacts[name] = contact
          store.save!
          render({"saved" => name})
        when "remove"
          name = one_arg!(arguments)
          raise Error, "contact not found: #{name}" unless store.contacts.key?(name)
          return if dry_run!({"operation" => "remove contact", "contact" => name})
          confirm!("Remove contact #{name}?")
          store.contacts.delete(name)
          store.save!
          render({"removed" => name})
        end
      end

      def api_read(arguments)
        require_args!(arguments, 0, exact: true)
        body = yield(client)
        render_response(body)
      end

      def domain_read(arguments)
        domain = one_arg!(arguments)
        body = yield(client, domain)
        render_response(body, domain: domain)
      end

      def dns_read(arguments)
        domain = one_arg!(arguments)
        sld, tld = split_domain(domain)
        render_response(yield(client.domains.dns, sld, tld), domain: domain)
      end

      def price(arguments)
        domain = one_arg!(arguments)
        action = (@options["--action"] || "register").upcase
        raise Error, "--action must be register or renew" unless %w[REGISTER RENEW].include?(action)

        quote = quote_for(domain, action, allow_raw: true)
        return if quote == :rendered

        render(quote, meta: {"domain" => domain, "environment" => resolved_config[:environment]})
      end

      def quote_for(domain, action, allow_raw: false)
        _sld, tld = split_domain(domain)
        body = client.users.get_pricing(
          product_type: "DOMAIN",
          params: api_params.merge("ProductCategory" => "DOMAINS", "ActionName" => action, "ProductName" => tld.upcase)
        )
        if allow_raw && @options["--raw"]
          renderer.render(body)
          return :rendered
        end

        parsed = XML.parse(body)
        prices = recursive_values(parsed, "price").flat_map { |value| value.is_a?(Array) ? value : [value] }
        years = Integer(@options["--years"] || 1)
        price = prices.find { |item| item.is_a?(Hash) && item["duration"].to_i == years } ||
          prices.find { |item| item.is_a?(Hash) }
        amount = price && (price["your_price"] || price["price"])
        currency = price && price["currency"]
        raise Error.new("Namecheap did not return an exact #{years}-year #{action.downcase} quote for .#{tld}", exit_code: 1) if blank?(amount) || blank?(currency)

        additional = price["your_additonal_cost"] || price["your_additional_cost"] || price["additional_cost"]
        total = BigDecimal(amount.to_s) + BigDecimal((additional || 0).to_s)
        {
          "domain" => domain,
          "action" => action.downcase,
          "years" => years,
          "price" => format("%.2f", total),
          "base_price" => amount,
          "additional_cost" => additional,
          "currency" => currency,
          "regular_price" => price["regular_price"],
          "coupon_price" => price["coupon_price"]
        }.compact
      end

      def set_lock(arguments)
        require_args!(arguments, 2, exact: true)
        domain, state = arguments
        enabled = case state.downcase
        when "on", "true", "locked" then "LOCK"
        when "off", "false", "unlocked" then "UNLOCK"
        else raise Error, "state must be on or off"
        end
        preview = {"operation" => "set registrar lock", "domain" => domain, "state" => state.downcase}
        return if dry_run!(preview)
        confirm!("Set registrar lock #{state.downcase} for #{domain}?")
        render_response(client.domains.set_registrar_lock(domain_name: domain, params: api_params.merge("LockAction" => enabled)), domain: domain)
      end

      def register(arguments)
        raise Error, "--raw is unavailable for composite registration; use --json for structured output" if @options["--raw"]

        domain = one_arg!(arguments)
        check = XML.parse(client.domains.check(domain_names: [domain]))
        domain_result = recursive_values(check, "domain_check_result").find { |value| value.is_a?(Hash) } ||
          (check if check.is_a?(Hash))
        available = domain_result && (domain_result["available"] == true || domain_result["available"].to_s.casecmp("true").zero?)
        raise Error.new("#{domain} is not available", exit_code: 1) unless available

        quote = premium_quote(domain_result, domain) || quote_for(domain, "REGISTER")
        contact = registration_contact
        preview = quote.merge("operation" => "register", "environment" => resolved_config[:environment], "profile" => selected_profile)
        return if dry_run!(preview)
        confirm!("Register #{domain} for #{quote["price"]} #{quote["currency"]}?")
        params = api_params
        if domain_result["is_premium_name"] == true || domain_result["is_premium_name"].to_s.casecmp("true").zero?
          params = params.merge(
            "IsPremiumDomain" => true,
            "PremiumPrice" => quote["price"],
            "EapFee" => domain_result["eap_fee"]
          ).compact
        end
        body = client.domains.create(
          domain_name: domain,
          years: Integer(@options["--years"] || 1),
          registrant: contact,
          tech: contact,
          admin: contact,
          aux_billing: contact,
          params: params
        )
        render_response(body, domain: domain)
      end

      def renew(arguments)
        raise Error, "--raw is unavailable for composite renewal; use --json for structured output" if @options["--raw"]

        domain = one_arg!(arguments)
        quote = quote_for(domain, "RENEW")
        preview = quote.merge("operation" => "renew", "environment" => resolved_config[:environment], "profile" => selected_profile)
        return if dry_run!(preview)
        confirm!("Renew #{domain} for #{quote["price"]} #{quote["currency"]}?")
        render_response(
          client.domains.renew(domain_name: domain, years: Integer(@options["--years"] || 1), params: api_params),
          domain: domain
        )
      end

      def premium_quote(result, domain)
        premium = result["is_premium_name"] == true || result["is_premium_name"].to_s.casecmp("true").zero?
        return unless premium

        amount = result["premium_registration_price"]
        currency = result["premium_registration_price_currency"] || result["currency"]
        raise Error.new("Namecheap did not return an exact premium registration quote for #{domain}", exit_code: 1) if blank?(amount) || blank?(currency)

        {"domain" => domain, "action" => "register", "years" => Integer(@options["--years"] || 1), "price" => amount, "currency" => currency, "premium" => true}
      end

      def registration_contact
        if @options["--contacts-file"]
          contact = load_document(@options["--contacts-file"])
        else
          name = @options["--contact"] || "default"
          contact = store.contacts[name] || raise(Error, "contact not found: #{name}; use --contacts-file or save it first")
        end
        validate_contact!(contact)
        contact
      end

      def dns_write(arguments, description)
        domain = one_arg!(arguments)
        sld, tld = split_domain(domain)
        preview = {"operation" => description, "domain" => domain}
        return if dry_run!(preview)
        confirm!("#{description} for #{domain}?")
        render_response(yield(client.domains.dns, sld, tld), domain: domain)
      end

      def custom_nameservers(arguments)
        require_args!(arguments, 2)
        domain, *nameservers = arguments
        sld, tld = split_domain(domain)
        preview = {"operation" => "set custom nameservers", "domain" => domain, "nameservers" => nameservers}
        return if dry_run!(preview)
        confirm!("Set custom nameservers for #{domain}?")
        render_response(client.domains.dns.set_custom(sld: sld, tld: tld, nameservers: nameservers, params: api_params), domain: domain)
      end

      def dns_records(action, arguments)
        domain = (action == "apply") ? require_args!(arguments, 1).first : one_arg!(arguments)
        file = arguments[1] if action == "apply"
        sld, tld = split_domain(domain)
        dns = client.domains.dns
        before_body = dns.get_hosts(sld: sld, tld: tld)
        before_parsed = XML.parse(before_body)
        before = host_records(before_parsed)
        email_type = @options["--email-type"] || find_key(before_parsed, "email_type")
        raise Error, "Namecheap did not return EmailType; pass --email-type" if blank?(email_type)

        after = case action
        when "add" then add_record(before)
        when "remove" then remove_record(before)
        when "apply"
          document = load_document(file || "-")
          email_type = document["email_type"] || document[:email_type] || email_type
          records = document["records"] || document[:records]
          raise Error, "zone.records must be a non-empty array" unless records.is_a?(Array) && records.any?
          records.map { |record| normalize_record(record) }
        end
        if after == before
          render({"operation" => action, "domain" => domain, "changed" => false}, meta: {"noop" => true})
          return
        end
        preview = {"operation" => action, "domain" => domain, "before" => before, "after" => after, "email_type" => email_type}
        return if dry_run!(preview)
        confirm!("#{action.capitalize} DNS records for #{domain}?")

        current = host_records(XML.parse(dns.get_hosts(sld: sld, tld: tld)))
        raise Error.new("DNS records changed after preview; retry the command", exit_code: 1) unless current == before
        body = dns.set_hosts(sld: sld, tld: tld, email_type: email_type, records: after, params: api_params)
        result = XML.parse(body)
        verified = host_records(XML.parse(dns.get_hosts(sld: sld, tld: tld)))
        raise Error.new("Namecheap accepted the update but verification differs", exit_code: 1) unless verified == after
        renderer.render(@options["--raw"] ? body : {"result" => result, "records" => verified}, meta: {"domain" => domain})
      end

      def add_record(records)
        record = record_from_options
        return records if records.include?(record)
        records + [record]
      end

      def remove_record(records)
        type = required_option("--type").upcase
        host = required_option("--host")
        matches = records.each_index.select do |index|
          record = records[index]
          record[:record_type].to_s.upcase == type && record[:host_name].to_s == host &&
            (!@options["--value"] || record[:address].to_s == @options["--value"])
        end
        raise Error, "matching DNS record was not found" if matches.empty?
        raise Error, "multiple records match; pass --value" if matches.length > 1
        records.each_index.reject { |index| index == matches.first }.map { |index| records[index] }
      end

      def record_from_options
        normalize_record(
          "host_name" => required_option("--host"),
          "record_type" => required_option("--type").upcase,
          "address" => required_option("--value"),
          "mx_pref" => @options["--mx-pref"],
          "ttl" => @options["--ttl"]
        )
      end

      def host_records(parsed)
        values = recursive_values(parsed, "host")
        values = values.flat_map { |value| value.is_a?(Array) ? value : [value] }
        values.select { |value| value.is_a?(Hash) }.map do |record|
          normalize_record(
            "host_name" => record["name"] || record["host_name"],
            "record_type" => record["type"] || record["record_type"],
            "address" => record["address"],
            "mx_pref" => record["mx_pref"],
            "ttl" => record["ttl"]
          )
        end
      end

      def normalize_record(record)
        record = record.transform_keys(&:to_s)
        normalized = {
          host_name: record["host_name"],
          record_type: record["record_type"].to_s.upcase,
          address: record["address"],
          ttl: blank?(record["ttl"]) ? nil : record["ttl"].to_i
        }
        if normalized[:record_type] == "MX" && !blank?(record["mx_pref"])
          normalized[:mx_pref] = record["mx_pref"].to_i
        end
        normalized.compact
      end

      def required_option(name)
        @options[name] || raise(Error, "#{name} is required")
      end

      def recursive_values(value, key)
        case value
        when Hash
          own = value.key?(key) ? [value[key]] : []
          own + value.values.flat_map { |child| recursive_values(child, key) }
        when Array
          value.flat_map { |child| recursive_values(child, key) }
        else []
        end
      end

      def find_key(value, key)
        recursive_values(value, key).first
      end

      def render_response(body, meta = {})
        renderer.render(@options["--raw"] ? body : XML.parse(body), meta: meta.merge("profile" => selected_profile, "environment" => resolved_config[:environment]))
      end

      def render(data, meta: {})
        renderer.render(data, meta: meta)
      end

      def renderer
        format = if @options["--raw"]
          :raw
        elsif @options["--json"]
          :json
        else
          :human
        end
        @renderer ||= Renderer.new(io: @stdout, format: format)
      end

      def client
        @client ||= Namecheap::API::Client.new(**resolved_config)
      end

      def resolved_config
        @resolved_config ||= begin
          profile = selected_profile && store.profiles[selected_profile] || {}
          file_values = @options["--env-file"] ? EnvFile.load(@options["--env-file"]) : {}
          process_values = credentials_from_environment(@env)
          env_file_values = credentials_from_environment(file_values)
          merged = profile.merge(process_values).merge(env_file_values)
          merged["environment"] = @options["--environment"] if @options["--environment"]
          merged["environment"] ||= "sandbox"
          merged["user_name"] ||= merged["api_user"]
          validate_environment!(merged["environment"])
          missing = %w[api_user api_key user_name client_ip].find { |key| blank?(merged[key]) }
          raise Error, "missing credential #{CREDENTIAL_ENV.fetch(missing.to_sym)}" if missing
          merged.transform_keys(&:to_sym).slice(:api_user, :api_key, :user_name, :client_ip, :environment)
        end
      end

      def selected_profile
        @options["--profile"] || store.data["default_profile"]
      end

      def credentials_from_environment(source)
        CREDENTIAL_ENV.to_h { |key, variable| [key.to_s, source[variable]] }.compact
      end

      def api_params
        @options["--params"] ? load_document(@options["--params"]) : {}
      end

      def load_document(path)
        content = (path == "-") ? @stdin.read : File.read(path)
        value = if File.extname(path).downcase == ".json" || content.lstrip.start_with?("{", "[")
          JSON.parse(content)
        else
          YAML.safe_load(content, permitted_classes: [], aliases: false)
        end
        raise Error, "input must contain a mapping" unless value.is_a?(Hash)
        value
      rescue Errno::ENOENT
        raise Error, "input file not found: #{path}"
      rescue JSON::ParserError, Psych::Exception => error
        raise Error, "invalid input: #{error.message}"
      end

      def validate_contact!(contact)
        required = Namecheap::API::Domains::REQUIRED_CONTACT_FIELDS.map(&:to_s)
        missing = required.find { |field| blank?(contact[field] || contact[field.to_sym]) }
        raise Error, "contact.#{missing} must be provided" if missing
      end

      def prompt_secret(label)
        @stderr.print("#{label}: ")
        value = @stdin.noecho(&:gets)&.chomp
        @stderr.puts
        value
      rescue NoMethodError
        raise Error, "#{label} must be supplied through the environment when stdin is not a terminal"
      end

      def confirm!(message)
        return if @options["--yes"]
        @stderr.print("#{message} [y/N] ")
        answer = @stdin.gets.to_s.strip
        raise Error.new("declined", exit_code: 3) unless answer.match?(/\Ay(?:es)?\z/i)
      end

      def dry_run!(preview)
        return false unless @options["--dry-run"]
        raise Error, "--raw cannot be combined with --dry-run" if @options["--raw"]
        render(preview, meta: {"dry_run" => true})
        true
      end

      def split_domain(domain)
        sld, tld = domain.to_s.split(".", 2)
        raise Error, "domain must include a top-level domain" if blank?(sld) || blank?(tld)
        [sld, tld]
      end

      def one_arg!(arguments)
        require_args!(arguments, 1, exact: true).first
      end

      def require_args!(arguments, count, exact: false)
        invalid = exact ? arguments.length != count : arguments.length < count
        raise Error, "expected #{count} argument#{"s" unless count == 1}" if invalid
        arguments
      end

      def validate_environment!(environment)
        raise Error, "environment must be sandbox or production" unless %w[sandbox production].include?(environment)
      end

      def blank?(value)
        value.nil? || value.to_s.empty?
      end

      def unknown_command(words)
        paths = Catalog::COMMANDS.map { |entry| entry["path"] }
        suggestion = nearest(words.join(" "), paths)
        Error.new("unknown command #{words.join(" ").inspect}. Try: namecheap help #{suggestion}")
      end

      def unknown_option(option)
        known = VALUE_OPTIONS + BOOLEAN_OPTIONS
        suggestion = nearest(option.split("=").first, known)
        Error.new("unknown option #{option.inspect}. Did you mean #{suggestion}?")
      end

      def nearest(value, candidates)
        candidates.min_by { |candidate| levenshtein(value, candidate) }
      end

      def levenshtein(left, right)
        row = (0..right.length).to_a
        left.each_char.with_index(1) do |left_char, index|
          previous = row
          row = [index]
          right.each_char.with_index(1) do |right_char, other_index|
            row << [row[-1] + 1, previous[other_index] + 1, previous[other_index - 1] + ((left_char == right_char) ? 0 : 1)].min
          end
        end
        row[-1]
      end
    end
  end
end
