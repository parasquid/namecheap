# Namecheap

The `main` branch contains the experimental instance-based rewrite of the `namecheap` gem. Version `2.0.0.pre` covers the current official API catalog and remains unreleased. It requires Ruby 3.3 or newer.

The former 0.3.x implementation is preserved without planned maintenance on the
`legacy/0.3` branch.

## Installation for development

Clone the repository and install the `main` branch dependencies:

```shell
git switch main
bundle install
```

The prerelease is not currently published to RubyGems.

## API setup

Enable API access in your Namecheap account and whitelist the public IPv4 address that will make requests. Sandbox and production use separate accounts and credentials.

Create an isolated client for one account and environment:

```ruby
client = Namecheap::API::Client.new(
  api_user: ENV.fetch("NAMECHEAP_API_USER"),
  api_key: ENV.fetch("NAMECHEAP_API_KEY"),
  user_name: ENV.fetch("NAMECHEAP_USERNAME"),
  client_ip: ENV.fetch("NAMECHEAP_CLIENT_IP"),
  environment: "sandbox"
)
```

`user_name` defaults to `api_user`, and `environment` defaults to `sandbox`. The API user, key, username, and [whitelisted client IP](https://www.namecheap.com/support/api/global-parameters/) must be non-empty. The environment must be either `sandbox` or `production`.

Avoid committing credentials to source control. Test against Namecheap's sandbox before using production.

## Command-line interface

The gem includes a `namecheap` executable for interactive use and automation. Its help is deliberately self-contained: it does not read credentials or make network requests.

```shell
bundle exec namecheap --help
bundle exec namecheap domains --help
bundle exec namecheap help domains register
bundle exec namecheap help --json
```

Use `.env.staging` directly for sandbox commands:

```shell
bundle exec namecheap domains list --env-file .env.staging
bundle exec namecheap domains check example.com --env-file .env.staging --json
bundle exec namecheap dns records list example.com --env-file .env.staging
```

Alternatively, save named profiles under the XDG config directory. API keys are prompted without echo and the config file is written with mode `0600`:

```shell
bundle exec namecheap config profiles add sandbox
bundle exec namecheap config profiles use sandbox
```

Read commands default to human output; `--json` emits `{"data": ..., "meta": ...}` and `--raw` preserves the upstream XML. Mutating commands support `--dry-run` and ask for confirmation unless `--yes` is supplied. Registration and renewal require an exact API quote before confirmation. DNS record add, remove, and apply preserve the complete zone, show a diff, reject drift, and verify the submitted result.

Generate valid structured-input examples with commands such as:

```shell
bundle exec namecheap help domains register --example contacts
bundle exec namecheap help dns records apply --example zone --format json
```

## Sandbox smoke tests

Copy `.env.example` to the ignored `.env.staging` file and fill it with sandbox-only credentials. The smoke script reads this file directly and refuses production environments.

Run authentication and read-only API checks:

```shell
bundle exec ruby script/sandbox_smoke
```

Run the separate CLI smoke checks:

```shell
bundle exec ruby script/cli_sandbox_smoke
```

The CLI smoke validates machine-readable help, domain listing, availability, pricing, and—when the sandbox account contains a domain—DNS listing plus a DNS add preview. Pass `--domain DOMAIN` to select an existing sandbox domain explicitly. The preview always uses `--dry-run` and does not submit a DNS change.

To register a persistent sandbox domain and verify domain, contact, and DNS writes:

```shell
bundle exec ruby script/sandbox_smoke --lifecycle
```

Namecheap does not delete or reset sandbox registrations. Use `--domain DOMAIN` with `--lifecycle` only when the supplied domain is available and may remain in the sandbox permanently.

An independent address lifecycle creates a temporary reseller-user address,
updates and reads it, briefly tests the default-address command when an existing
default can be restored, and deletes the temporary address:

```shell
bundle exec ruby script/sandbox_smoke --address-lifecycle
```

## Domains and DNS

The v2 client implements the domain and DNS commands available in 0.3.1 using keyword arguments:

```ruby
client.domains.get_list
client.domains.get_list(params: {"Page" => 2, "PageSize" => 50})
client.domains.get_contacts(domain_name: "example.com")
client.domains.get_tld_list
client.domains.check(domain_names: ["example.com", "example.net"])
client.domains.renew(domain_name: "example.com", years: 1)
client.domains.get_info(domain_name: "example.com")

client.domains.dns.set_default(sld: "example", tld: "com")
client.domains.dns.get_list(sld: "example", tld: "com")
client.domains.dns.get_hosts(sld: "example", tld: "com")
```

Each call returns `Namecheap::API::Response`. Parsed result data uses snake-case symbol keys, and the exact upstream XML remains available through `response.raw_body`:

```ruby
response = client.domains.get_list(page: 2, page_size: 50)
response.data
response.paging
response.raw_body
```

Namecheap API failures raise `Namecheap::API::ApiError`; transport and malformed-response failures raise `TransportError` and `ParseError`. Caller parameters cannot replace `ApiUser`, `ApiKey`, `UserName`, `ClientIp`, or `Command`.

Domain creation and contact updates accept four contact hashes. Each requires `first_name`, `last_name`, `address_1`, `city`, `state_province`, `postal_code`, `country`, `phone`, and `email_address`:

```ruby
contact = {
  first_name: "Example",
  last_name: "Person",
  address_1: "1 Example Street",
  city: "Example City",
  state_province: "CA",
  postal_code: "90210",
  country: "US",
  phone: "+1.5555550100",
  email_address: "person@example.com"
}

client.domains.create(
  domain_name: "example.com",
  years: 1,
  registrant: contact,
  tech: contact,
  admin: contact,
  aux_billing: contact
)
```

DNS host replacement accepts the complete desired record set:

```ruby
client.domains.dns.set_hosts(
  sld: "example",
  tld: "com",
  email_type: "MX",
  records: [
    {host_name: "@", record_type: "A", address: "192.0.2.10", ttl: 1800},
    {host_name: "@", record_type: "MX", address: "mail.example.net", mx_pref: 10}
  ]
)
```

`set_hosts` is destructive: Namecheap deletes existing host records omitted from the request. `client.users.get_pricing` supports exact CLI quotes.

## Additional resources

The rewrite covers the maintained 0.3.1 command groups using nested resources:

```ruby
client.domains.nameservers.get_info(
  sld: "example",
  tld: "com",
  nameserver: "ns1.example.com"
)
client.domains.transfers.get_list
client.ssl.get_list
client.users.get_balances
client.users.addresses.get_list
client.domain_privacy.get_list
```

The current domain-privacy API no longer catalogs the old `allot`, `discard`,
or `unallot` operations. The v2 resource instead exposes `change_email_address`,
`enable`, `disable`, `get_list`, and `renew`, while preserving Namecheap's
documented `whoisguard` wire-command names.

Every public resource command is discoverable through the CLI. Major groups
include `domains nameservers`, `domains transfers`, `ssl`, `users`, and
`domain-privacy`. Run `bundle exec namecheap help --json` for the complete
manifest.

The current official catalog contains 59 commands, including all six
`users.address` operations and the SSL SAN purchase, certificate revocation,
and DCV-edit operations. See [the coverage matrix](docs/api-coverage.md) for
the Ruby, CLI, and smoke mapping.

Durable secrets are never accepted as command-line values. Interactive commands
prompt without echo; automation uses standard input or an input file accessible
only by its owner. Paid commands use an exact pricing API quote when available.
Domain-privacy renewal, for which Namecheap exposes no quote API, requires
`--expected-price` and `--currency` and verifies the returned charge afterward.

## Roadmap

GitHub [open issues](https://github.com/parasquid/namecheap/issues) are the
project roadmap. Each planned change should have a focused issue that describes
its scope and completion criteria.

## Development

Run the tests and Standard Ruby checks:

```shell
bundle exec rake
```

Build the prerelease locally:

```shell
bundle exec gem build namecheap.gemspec
```

Changing the version, pushing a branch, or building the gem does not publish a
release. To release a finalized version:

1. Update `Namecheap::VERSION` and replace the matching changelog's
   `(unreleased)` heading with a finalized version heading.
2. Merge the release preparation into `main` and confirm CI passes.
3. Create and push an annotated signed tag that exactly matches the version:

   ```shell
   git tag -s v2.0.0.pre -m "Release v2.0.0.pre"
   git push origin v2.0.0.pre
   ```

GitHub must recognize the tag signature as verified. The release workflow then
re-runs the tests and style checks, publishes through RubyGems trusted
publishing, and creates a matching GitHub Release. Prerelease gem versions
produce prerelease GitHub Releases.

Before the first automated release, a `namecheap` gem owner must register the
GitHub Actions trusted publisher on RubyGems.org with owner `parasquid`,
repository `namecheap`, workflow `release.yml`, and environment `release`. This
is a one-time account setting; the repository does not store a RubyGems API key.

## License

Copyright © 2011–2026 Tristan V. Gomez and contributors. This project is
available under the GNU Lesser General Public License, version 3 or any later
version. See [COPYING](COPYING).
