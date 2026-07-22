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

## Implemented API

The current prototype implements these calls:

```ruby
client.domains.get_list
client.domains.get_list(params: {"Page" => 2, "PageSize" => 50})
client.domains.get_contacts(domain_name: "example.com")
client.domains.dns.get_list(sld: "example", tld: "com")
```

Each call returns the raw Faraday response body. Caller parameters cannot replace `ApiUser`, `ApiKey`, `UserName`, `ClientIp`, or `Command`.

Domain creation and the SSL, users, and WhoisGuard resources are intentionally unfinished and raise `NotImplementedError`.

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
