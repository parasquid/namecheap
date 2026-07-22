# Namecheap v2

This branch contains the experimental instance-based rewrite of the `namecheap` gem. Version `2.0.0.pre` is incomplete and unreleased. It requires Ruby 3.3 or newer.

For the maintained 0.3.x API, use the repository's `master` branch.

## Installation for development

Clone this branch and install its dependencies:

```shell
git switch v2.0
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

`user_name` defaults to `api_user`, and `environment` defaults to `sandbox`. The API user, key, username, and whitelisted client IP must be non-empty. The environment must be either `sandbox` or `production`.

Avoid committing credentials to source control. Test against Namecheap's sandbox before using production.

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

Each call returns the raw Faraday response body. Caller parameters cannot replace `ApiUser`, `ApiKey`, `UserName`, `ClientIp`, or `Command`.

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

`set_hosts` is destructive: Namecheap deletes existing host records omitted from the request. The SSL, users, and WhoisGuard resources remain unfinished and raise `NotImplementedError`.

## Development

Run the tests and Standard Ruby checks:

```shell
bundle exec rake
```

Build the prerelease locally:

```shell
bundle exec gem build namecheap.gemspec
```

Changing the version or pushing this branch does not publish the gem or create a release. Publishing remains a separate manual action.

## License

Copyright 2011 Tristan V. Gomez. This project is available under the GNU Lesser General Public License, version 3 or any later version. See [COPYING](COPYING).
