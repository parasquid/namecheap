require "json"
require "bigdecimal"
require "io/console"
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
        --params --input --years --action --type --host --value --mx-pref --ttl --email-type
        --amount --return-url --expected-price --currency
        --count
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
      rescue Namecheap::API::Error => error
        @stderr.puts("Error: #{error.message}")
        1
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
        when ["domains contacts set", "contacts"]
          contact = {"first_name" => "Ada", "last_name" => "Lovelace", "address_1" => "1 Example Street", "city" => "London", "state_province" => "London", "postal_code" => "SW1A 1AA", "country" => "GB", "phone" => "+44.1234567890", "email_address" => "ada@example.test"}
          {"registrant" => contact, "tech" => contact, "admin" => contact, "aux_billing" => contact}
        when ["domains register", "params"]
          {"ExtendedAttributeName" => "value"}
        when ["dns records apply", "zone"]
          {"email_type" => "MXE", "records" => [{"host_name" => "@", "record_type" => "A", "address" => "192.0.2.10", "ttl" => 1800}]}
        when ["dns forwarding set", "forwardings"]
          {"forwardings" => [{"mailbox" => "info", "forward_to" => "person@example.test"}]}
        when ["domains transfers create", "transfer"]
          {"epp_code" => "replace-with-transfer-code", "years" => 1}
        when ["users create", "user"]
          {
            "user_name" => "reseller-user",
            "password" => "replace-with-password",
            "accept_terms" => 1,
            "profile" => user_profile_example
          }
        when ["users update", "user-profile"]
          {"profile" => user_profile_example}
        when ["users login", "password"]
          {"password" => "replace-with-password"}
        when ["users password change", "password-change"]
          {"old_password" => "replace-with-old-password", "new_password" => "replace-with-new-password"}
        when ["users addresses create", "address"], ["users addresses update", "address"]
          {
            "address_name" => "primary",
            "default" => false,
            "address" => user_profile_example.merge("state_province_choice" => "P")
          }
        when ["ssl dcv edit", "ssl-dcv"]
          {"domain_methods" => {"example.com" => "CNAME_CSR_HASH", "www.example.com" => "HTTP_CSR_HASH"}}
        else
          raise Error, "unknown example #{name.inspect}; run namecheap help #{path.join(" ")} --json"
        end
        format = @options["--format"] || "yaml"
        raise Error, "--format must be yaml or json" unless %w[yaml json].include?(format)

        @stdout.write((format == "json") ? JSON.pretty_generate(content) + "\n" : YAML.dump(content))
        0
      end

      def user_profile_example
        {
          "first_name" => "Ada",
          "last_name" => "Lovelace",
          "address_1" => "1 Example Street",
          "city" => "London",
          "state_province" => "London",
          "postal_code" => "SW1A 1AA",
          "country" => "GB",
          "email_address" => "ada@example.test",
          "phone" => "+44.1234567890"
        }
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
        when "domains contacts set" then set_contacts(arguments)
        when "domains tlds" then api_read(arguments) { |api| api.domains.get_tld_list(params: api_params) }
        when "domains price" then price(arguments)
        when "domains lock status" then domain_read(arguments) { |api, domain| api.domains.get_registrar_lock(domain_name: domain, params: api_params) }
        when "domains lock set" then set_lock(arguments)
        when "domains register" then register(arguments)
        when "domains renew" then renew(arguments)
        when "domains reactivate" then reactivate(arguments)
        when /\Adomains nameservers / then registered_nameserver(path.split.last, arguments)
        when /\Adomains transfers / then transfer_command(path.split.last, arguments)
        when "dns nameservers list" then dns_read(arguments) { |dns, sld, tld| dns.get_list(sld: sld, tld: tld, params: api_params) }
        when "dns nameservers default" then dns_write(arguments, "Use Namecheap default DNS") { |dns, sld, tld| dns.set_default(sld: sld, tld: tld, params: api_params) }
        when "dns nameservers custom" then custom_nameservers(arguments)
        when "dns records list" then dns_read(arguments) { |dns, sld, tld| dns.get_hosts(sld: sld, tld: tld, params: api_params) }
        when "dns records add", "dns records remove", "dns records apply" then dns_records(path.split.last, arguments)
        when "dns forwarding list" then domain_read(arguments) { |api, domain| api.domains.dns.get_email_forwarding(domain_name: domain, params: api_params) }
        when "dns forwarding set" then set_forwarding(arguments)
        when /\Assl / then ssl_command(path.sub("ssl ", ""), arguments)
        when /\Ausers addresses / then address_command(path.sub("users addresses ", ""), arguments)
        when /\Ausers / then user_api_command(path.sub("users ", ""), arguments)
        when /\Adomain-privacy / then privacy_command(path.sub("domain-privacy ", ""), arguments)
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
        params = api_params.merge("ProductCategory" => "DOMAINS", "ActionName" => action, "ProductName" => tld.upcase)
        body = client.users.get_pricing(product_type: "DOMAIN", params: params)
        if allow_raw && @options["--raw"]
          renderer.render(body)
          return :rendered
        end

        years = Integer(@options["--years"] || 1)
        quote_from_body(body, years: years, description: "#{action.downcase} quote for .#{tld}")
          .merge("domain" => domain, "action" => action.downcase)
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
        contacts = registration_contacts
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
          **contacts,
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

      def product_quote(product_type:, product_category:, action:, product_name:, years:)
        params = api_params
        category = params["ProductCategory"] || params[:ProductCategory] || product_category
        body = client.users.get_pricing(
          product_type: product_type,
          params: params.merge(
            "ProductCategory" => category,
            "ActionName" => action,
            "ProductName" => product_name
          )
        )
        quote_from_body(
          body,
          years: years,
          description: "#{action.downcase} quote for #{product_name}"
        ).merge(
          "product_type" => product_type,
          "product_name" => product_name,
          "action" => action.downcase
        )
      end

      def quote_from_body(body, years:, description:)
        parsed = XML.parse(body)
        prices = recursive_values(parsed, "price").flat_map { |value| value.is_a?(Array) ? value : [value] }
        price = prices.find { |item| item.is_a?(Hash) && item["duration"].to_i == years }
        amount = price && (price["your_price"] || price["price"])
        currency = price && price["currency"]
        raise Error.new("Namecheap did not return an exact #{years}-year #{description}", exit_code: 1) if blank?(amount) || blank?(currency)

        additional = price["your_additonal_cost"] || price["your_additional_cost"] || price["additional_cost"]
        total = BigDecimal(amount.to_s) + BigDecimal((additional || 0).to_s)
        {
          "years" => years,
          "price" => format("%.2f", total),
          "base_price" => amount,
          "additional_cost" => additional,
          "currency" => currency,
          "regular_price" => price["regular_price"],
          "coupon_price" => price["coupon_price"]
        }.compact
      end

      def registration_contacts
        if @options["--contacts-file"]
          document = load_document(@options["--contacts-file"])
          return contact_groups(document)
        else
          name = @options["--contact"] || "default"
          contact = store.contacts[name] || raise(Error, "contact not found: #{name}; use --contacts-file or save it first")
        end
        validate_contact!(contact)
        %i[registrant tech admin aux_billing].to_h { |key| [key, contact] }
      end

      def set_contacts(arguments)
        require_args!(arguments, 1)
        domain = arguments.first
        document = load_document(arguments[1] || @options["--input"] || "-")
        contacts = contact_groups(document)
        preview = {"operation" => "set contacts", "domain" => domain, "contacts" => redact(document)}
        return if dry_run!(preview)

        confirm!("Replace contacts for #{domain}?")
        render_response(
          client.domains.set_contacts(domain_name: domain, **contacts, params: api_params),
          domain: domain
        )
      end

      def reactivate(arguments)
        domain = one_arg!(arguments)
        years = Integer(@options["--years"] || 1)
        quote = quote_for(domain, "REACTIVATE")
        preview = quote.merge("operation" => "reactivate", "environment" => resolved_config[:environment])
        return if dry_run!(preview)

        confirm!("Reactivate #{domain} for #{quote["price"]} #{quote["currency"]}?")
        render_response(
          client.domains.reactivate(domain_name: domain, params: api_params.merge("YearsToAdd" => years)),
          domain: domain
        )
      end

      def registered_nameserver(action, arguments)
        nameservers = client.domains.nameservers
        case action
        when "create"
          require_args!(arguments, 3, exact: true)
          domain, nameserver, ip = arguments
          sld, tld = split_domain(domain)
          mutate("create registered nameserver", domain: domain, nameserver: nameserver, ip: ip) do
            nameservers.create(sld: sld, tld: tld, nameserver: nameserver, ip: ip, params: api_params)
          end
        when "delete"
          require_args!(arguments, 2, exact: true)
          domain, nameserver = arguments
          sld, tld = split_domain(domain)
          mutate("delete registered nameserver", domain: domain, nameserver: nameserver) do
            nameservers.delete(sld: sld, tld: tld, nameserver: nameserver, params: api_params)
          end
        when "info"
          require_args!(arguments, 2, exact: true)
          domain, nameserver = arguments
          sld, tld = split_domain(domain)
          render_response(nameservers.get_info(sld: sld, tld: tld, nameserver: nameserver, params: api_params), domain: domain)
        when "update"
          require_args!(arguments, 4, exact: true)
          domain, nameserver, old_ip, ip = arguments
          sld, tld = split_domain(domain)
          mutate("update registered nameserver", domain: domain, nameserver: nameserver, old_ip: old_ip, ip: ip) do
            nameservers.update(
              sld: sld,
              tld: tld,
              nameserver: nameserver,
              old_ip: old_ip,
              ip: ip,
              params: api_params
            )
          end
        end
      end

      def transfer_command(action, arguments)
        transfers = client.domains.transfers
        case action
        when "list"
          require_args!(arguments, 0, exact: true)
          render_response(transfers.get_list(params: api_params))
        when "status"
          render_response(transfers.get_status(transfer_id: positive_integer_argument!("transfer_id", one_arg!(arguments)), params: api_params))
        when "resubmit"
          transfer_id = positive_integer_argument!("transfer_id", one_arg!(arguments))
          mutate("resubmit transfer", transfer_id: transfer_id) do
            transfers.update_status(transfer_id: transfer_id, resubmit: true, params: api_params)
          end
        when "create"
          domain = one_arg!(arguments)
          input = if @options["--input"]
            sensitive_document(@options["--input"], required: %w[epp_code])
          else
            {"epp_code" => prompt_secret("EPP code")}
          end
          years = Integer(@options["--years"] || input["years"] || 1)
          _sld, tld = split_domain(domain)
          quote = product_quote(
            product_type: "DOMAIN",
            product_category: "DOMAINS",
            action: "TRANSFER",
            product_name: tld.upcase,
            years: years
          )
          preview = quote.merge("operation" => "transfer", "domain" => domain)
          return if dry_run!(preview)

          confirm!("Transfer #{domain} for #{quote["price"]} #{quote["currency"]}?")
          render_response(
            transfers.create(
              domain_name: domain,
              years: years,
              epp_code: input.fetch("epp_code"),
              params: api_params
            ),
            domain: domain
          )
        end
      end

      def set_forwarding(arguments)
        require_args!(arguments, 1)
        domain = arguments.first
        document = load_document(arguments[1] || @options["--input"] || "-")
        forwardings = document["forwardings"] || document[:forwardings]
        raise Error, "forwardings must be a non-empty array" unless forwardings.is_a?(Array) && forwardings.any?

        mutate("replace email forwarding", domain: domain, forwardings: forwardings) do
          client.domains.dns.set_email_forwarding(
            domain_name: domain,
            forwardings: forwardings,
            params: api_params
          )
        end
      end

      def ssl_command(action, arguments)
        ssl = client.ssl
        case action
        when "list"
          require_args!(arguments, 0, exact: true)
          render_response(ssl.get_list(params: api_params))
        when "info"
          certificate_id = positive_integer_argument!("certificate_id", one_arg!(arguments))
          render_response(ssl.get_info(certificate_id: certificate_id, params: api_params))
        when "parse-csr"
          csr = read_file(one_arg!(arguments))
          render_response(ssl.parse_csr(csr: csr, params: api_params_with_type("CertificateType")))
        when "approver-emails"
          domain = one_arg!(arguments)
          render_response(
            ssl.get_approver_email_list(
              domain_name: domain,
              certificate_type: required_option("--type"),
              params: api_params
            ),
            domain: domain
          )
        when "create"
          require_args!(arguments, 0, exact: true)
          years = Integer(required_option("--years"))
          type = required_option("--type")
          quote = if api_params.keys.map(&:to_s).include?("SANSToAdd")
            expected_price.merge("years" => years, "product_name" => type)
          else
            product_quote(
              product_type: "SSLCERTIFICATE",
              product_category: "COMODO",
              action: "PURCHASE",
              product_name: type,
              years: years
            )
          end
          paid_mutation("purchase SSL", quote) do
            ssl.create(years: years, certificate_type: type, params: api_params)
          end
        when "renew"
          certificate_id = positive_integer_argument!("certificate_id", one_arg!(arguments))
          years = Integer(required_option("--years"))
          type = required_option("--type")
          quote = product_quote(
            product_type: "SSLCERTIFICATE",
            product_category: "COMODO",
            action: "RENEW",
            product_name: type,
            years: years
          )
          paid_mutation("renew SSL", quote.merge("certificate_id" => certificate_id)) do
            ssl.renew(
              certificate_id: certificate_id,
              years: years,
              certificate_type: type,
              params: api_params
            )
          end
        when "activate", "reissue"
          require_args!(arguments, 2, exact: true)
          certificate_id, csr_path = arguments
          certificate_id = positive_integer_argument!("certificate_id", certificate_id)
          csr = read_file(csr_path)
          mutate("#{action} SSL", certificate_id: certificate_id) do
            if action == "activate"
              ssl.activate(certificate_id: certificate_id, csr: csr, params: api_params)
            else
              ssl.reissue(certificate_id: certificate_id, csr: csr, params: api_params)
            end
          end
        when "resend approver"
          certificate_id = positive_integer_argument!("certificate_id", one_arg!(arguments))
          mutate("resend SSL approver email", certificate_id: certificate_id) do
            ssl.resend_approver_email(certificate_id: certificate_id, params: api_params)
          end
        when "resend fulfillment"
          certificate_id = positive_integer_argument!("certificate_id", one_arg!(arguments))
          mutate("resend SSL fulfillment email", certificate_id: certificate_id) do
            ssl.resend_fulfillment_email(certificate_id: certificate_id, params: api_params)
          end
        when "sans purchase"
          certificate_id = positive_integer_argument!("certificate_id", one_arg!(arguments))
          count = Integer(required_option("--count"))
          quote = expected_price.merge("certificate_id" => certificate_id, "count" => count)
          paid_mutation("purchase additional SSL SANs", quote) do
            ssl.purchase_more_sans(certificate_id: certificate_id, count: count, params: api_params)
          end
        when "revoke"
          certificate_id = positive_integer_argument!("certificate_id", one_arg!(arguments))
          certificate_type = required_option("--type")
          mutate("irreversibly revoke SSL certificate", certificate_id: certificate_id, certificate_type: certificate_type) do
            ssl.revoke_certificate(
              certificate_id: certificate_id,
              certificate_type: certificate_type,
              params: api_params
            )
          end
        when "dcv edit"
          require_args!(arguments, 1)
          raise Error, "expected CERTIFICATE_ID and at most one input file" if arguments.length > 2

          certificate_id = positive_integer_argument!("certificate_id", arguments.first)
          input = load_document(arguments[1] || @options["--input"] || "-").transform_keys(&:to_s)
          mutate(
            "edit SSL domain-control validation",
            certificate_id: certificate_id,
            dcv_method: input["dcv_method"],
            domain_methods: input["domain_methods"]
          ) do
            ssl.edit_dcv_method(
              certificate_id: certificate_id,
              dcv_method: input["dcv_method"],
              domain_methods: input["domain_methods"],
              params: api_params
            )
          end
        end
      end

      def address_command(action, arguments)
        addresses = client.users.addresses
        case action
        when "list"
          require_args!(arguments, 0, exact: true)
          render_response(addresses.get_list(params: api_params))
        when "info"
          address_id = positive_integer_argument!("address_id", one_arg!(arguments))
          render_response(addresses.get_info(address_id: address_id, params: api_params))
        when "delete"
          address_id = positive_integer_argument!("address_id", one_arg!(arguments))
          mutate("delete user address", address_id: address_id) do
            addresses.delete(address_id: address_id, params: api_params)
          end
        when "default"
          address_id = positive_integer_argument!("address_id", one_arg!(arguments))
          mutate("set default user address", address_id: address_id) do
            addresses.set_default(address_id: address_id, params: api_params)
          end
        when "create"
          input = load_document(input_path(arguments)).transform_keys(&:to_s)
          address = input["address"]
          raise Error, "input.address must be provided" unless address.is_a?(Hash)

          address_name = input["address_name"]
          raise Error, "input.address_name must be provided" if blank?(address_name)

          default = input.key?("default") ? input["default"] : false
          mutate("create user address", address_name: address_name, address: address, default: default) do
            addresses.create(
              address_name: address_name,
              address: address,
              default: default,
              params: api_params
            )
          end
        when "update"
          require_args!(arguments, 1)
          raise Error, "expected ADDRESS_ID and at most one input file" if arguments.length > 2

          address_id = positive_integer_argument!("address_id", arguments.first)
          input = load_document(arguments[1] || @options["--input"] || "-").transform_keys(&:to_s)
          address = input["address"]
          raise Error, "input.address must be provided" unless address.is_a?(Hash)

          address_name = input["address_name"]
          raise Error, "input.address_name must be provided" if blank?(address_name)

          mutate("update user address", address_id: address_id, address_name: address_name, address: address) do
            addresses.update(
              address_id: address_id,
              address_name: address_name,
              address: address,
              default: input["default"],
              params: api_params
            )
          end
        end
      end

      def user_api_command(action, arguments)
        users = client.users
        case action
        when "pricing"
          product_type = one_arg!(arguments)
          render_response(users.get_pricing(product_type: product_type, params: api_params))
        when "balances"
          require_args!(arguments, 0, exact: true)
          render_response(users.get_balances(params: api_params))
        when "create"
          input = sensitive_document(input_path(arguments), required: %w[user_name password profile accept_terms])
          mutate("create user", user_name: input["user_name"], profile: redact(input["profile"])) do
            users.create(
              user_name: input.fetch("user_name"),
              password: input.fetch("password"),
              profile: input.fetch("profile"),
              accept_terms: input.fetch("accept_terms"),
              params: api_params
            )
          end
        when "update"
          input = load_document(input_path(arguments))
          profile = input["profile"] || input
          mutate("update user", profile: profile) { users.update(profile: profile, params: api_params) }
        when "login"
          path = optional_input_path(arguments)
          input = path ? sensitive_document(path, required: %w[password]) : {"password" => prompt_secret("Password")}
          render_response(users.login(password: input.fetch("password"), params: api_params))
        when "password change"
          input = sensitive_document(input_path(arguments), required: %w[new_password])
          mutate("change user password") do
            users.change_password(
              new_password: input.fetch("new_password"),
              old_password: input["old_password"],
              reset_code: input["reset_code"],
              params: api_params
            )
          end
        when "password reset"
          require_args!(arguments, 2, exact: true)
          find_by, value = arguments
          mutate("send password reset", find_by: find_by, value: value) do
            users.reset_password(find_by: find_by, find_by_value: value, params: api_params)
          end
        when "funds request"
          user_name = one_arg!(arguments)
          amount = required_option("--amount")
          return_url = required_option("--return-url")
          mutate("create add-funds request", user_name: user_name, amount: amount, return_url: return_url) do
            users.create_add_funds_request(
              user_name: user_name,
              payment_type: "CreditCard",
              amount: amount,
              return_url: return_url,
              params: api_params
            )
          end
        when "funds status"
          render_response(users.get_add_funds_status(token_id: one_arg!(arguments), params: api_params))
        end
      end

      def privacy_command(action, arguments)
        privacy = client.domain_privacy
        case action
        when "list"
          require_args!(arguments, 0, exact: true)
          render_response(privacy.get_list(params: api_params))
        when "enable"
          require_args!(arguments, 2, exact: true)
          id, email = arguments
          id = positive_integer_argument!("whoisguard_id", id)
          mutate("enable domain privacy", id: id, forwarded_to_email: email) do
            privacy.enable(whoisguard_id: id, forwarded_to_email: email, params: api_params)
          end
        when "disable"
          id = positive_integer_argument!("whoisguard_id", one_arg!(arguments))
          mutate("disable domain privacy", id: id) { privacy.disable(whoisguard_id: id, params: api_params) }
        when "email rotate"
          id = positive_integer_argument!("whoisguard_id", one_arg!(arguments))
          mutate("rotate domain privacy email", id: id) do
            privacy.change_email_address(whoisguard_id: id, params: api_params)
          end
        when "renew"
          id = positive_integer_argument!("whoisguard_id", one_arg!(arguments))
          years = Integer(required_option("--years"))
          expected = expected_price
          paid_mutation("renew domain privacy", expected.merge("id" => id, "years" => years)) do
            privacy.renew(whoisguard_id: id, years: years, params: api_params)
          end
        end
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
        renderer.render(@options["--raw"] ? body.raw_body : {"result" => result, "records" => verified}, meta: {"domain" => domain})
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
            "host_name" => record[:name] || record["name"] || record[:host_name] || record["host_name"],
            "record_type" => record[:type] || record["type"] || record[:record_type] || record["record_type"],
            "address" => record[:address] || record["address"],
            "mx_pref" => record[:mx_pref] || record["mx_pref"],
            "ttl" => record[:ttl] || record["ttl"]
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
          symbol_key = key.to_sym
          own = if value.key?(key)
            [value[key]]
          elsif value.key?(symbol_key)
            [value[symbol_key]]
          else
            []
          end
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
        value = @options["--raw"] ? body.raw_body : XML.parse(body)
        response_meta = meta.merge(
          "profile" => selected_profile,
          "environment" => resolved_config[:environment]
        )
        response_meta["paging"] = body.paging if body.paging
        renderer.render(value, meta: response_meta)
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

      def api_params_with_type(field)
        type = @options["--type"]
        type ? api_params.merge(field => type) : api_params
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

      def sensitive_document(path, required:)
        @consumed_stdin = true if path == "-"
        check_private_file!(path) unless path == "-"
        value = load_document(path)
        missing = required.find { |key| blank?(value[key] || value[key.to_sym]) }
        raise Error, "input.#{missing} must be provided" if missing

        value.transform_keys(&:to_s)
      end

      def check_private_file!(path)
        mode = File.stat(path).mode & 0o077
        raise Error, "sensitive input file must not be accessible by group or others: #{path}" unless mode.zero?
      rescue Errno::ENOENT
        raise Error, "input file not found: #{path}"
      end

      def read_file(path)
        File.read(path)
      rescue Errno::ENOENT
        raise Error, "input file not found: #{path}"
      end

      def input_path(arguments)
        require_args!(arguments, 0) if arguments.empty?
        raise Error, "expected at most one input file" if arguments.length > 1

        arguments.first || @options["--input"] || "-"
      end

      def optional_input_path(arguments)
        raise Error, "expected at most one input file" if arguments.length > 1

        arguments.first || @options["--input"]
      end

      def contact_groups(document)
        document = document.transform_keys(&:to_s)
        keys = %w[registrant tech admin aux_billing]
        if keys.all? { |key| document[key].is_a?(Hash) }
          keys.to_h { |key| [key.to_sym, document.fetch(key)] }
        else
          validate_contact!(document)
          keys.to_h { |key| [key.to_sym, document] }
        end
      end

      def mutate(operation, preview = {})
        preview = redact(preview.merge("operation" => operation))
        return if dry_run!(preview)

        confirm!("#{operation.capitalize}?")
        body = yield
        render_response(body)
      end

      def paid_mutation(operation, quote)
        preview = redact(quote.merge("operation" => operation))
        return if dry_run!(preview)

        confirm!("#{operation.capitalize} for #{quote.fetch("price")} #{quote.fetch("currency")}?")
        body = yield
        verify_expected_charge!(body, quote) if quote["quote_source"] == "user"
        render_response(body)
      end

      def expected_price
        amount = required_option("--expected-price")
        currency = required_option("--currency").upcase
        BigDecimal(amount)
        {
          "price" => format("%.2f", BigDecimal(amount)),
          "currency" => currency,
          "quote_source" => "user",
          "warning" => "Namecheap provides no preflight quote; this expected price is checked only after execution"
        }
      rescue ArgumentError
        raise Error, "--expected-price must be a number"
      end

      def verify_expected_charge!(body, quote)
        parsed = XML.parse(body)
        actual = recursive_values(parsed, "charged_amount").first
        raise Error.new("Namecheap did not return ChargedAmount for verification", exit_code: 1) if blank?(actual)
        return if BigDecimal(actual.to_s) == BigDecimal(quote.fetch("price"))

        raise Error.new(
          "Namecheap charged #{actual} instead of expected #{quote.fetch("price")} #{quote.fetch("currency")}",
          exit_code: 1
        )
      end

      def redact(value)
        case value
        when Hash
          value.to_h do |key, child|
            sensitive = key.to_s.match?(/api.?key|password|epp.?code|reset.?code|secret/i)
            [key, sensitive ? "[redacted]" : redact(child)]
          end
        when Array
          value.map { |child| redact(child) }
        else
          value
        end
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
        raise Error, "--yes is required when sensitive input is read from stdin" if @consumed_stdin

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

      def positive_integer_argument!(name, value)
        parsed = Integer(value, exception: false)
        raise Error, "#{name} must be a positive integer" unless parsed&.positive?

        parsed
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
