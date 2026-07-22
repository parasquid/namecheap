# Namecheap

`namecheap` is a Ruby wrapper for the [Namecheap XML API](https://www.namecheap.com/support/api/intro/). It supports the existing domains, DNS, nameserver, transfer, SSL, user, and domain privacy commands exposed by the gem.

Version 0.3.1 requires Ruby 3.3 or newer.

## Installation

Add the gem to your bundle:

```ruby
gem "namecheap"
```

Then run `bundle install`.

## API setup

Enable API access in your Namecheap account and whitelist the public IPv4 address that will make requests. Sandbox and production use separate accounts and credentials.

The gem uses the sandbox endpoint unless `RACK_ENV` (or `Rails.env`) is `production`. Test requests against the sandbox before enabling production:

```ruby
Namecheap.configure do |config|
  config.key = ENV.fetch("NAMECHEAP_API_KEY")
  config.username = ENV.fetch("NAMECHEAP_USERNAME")
  config.client_ip = ENV.fetch("NAMECHEAP_CLIENT_IP")
end
```

Avoid committing API keys or account configuration to source control.

## Usage

The resource methods mirror Namecheap command names:

```ruby
Namecheap.domains.get_list
Namecheap.domains.check(["example.com", "example.net"])
Namecheap.dns.get_hosts("example", "com")
```

Additional command parameters can be passed as a final hash:

```ruby
Namecheap.domains.get_list(page: 2, page_size: 50)
```

Namecheap returns XML responses. This version returns the `HTTParty::Response` directly so existing applications can inspect the parsed response, status, and headers.

Configuration can also be loaded from an ERB-enabled YAML file. The selected top-level key must match `RACK_ENV`, or `development` when it is unset:

```yaml
development:
  username: sandbox_user
  key: <%= ENV.fetch("NAMECHEAP_API_KEY") %>
  client_ip: 192.0.2.1
```

```ruby
Namecheap::Config.load!("config/namecheap.yml")
```

## Development

Install dependencies and run the test and style checks:

```shell
bundle install
bundle exec rake
```

Build a local gem without publishing it:

```shell
bundle exec gem build namecheap.gemspec
```

Publishing is intentionally manual. Changing the version does not publish a gem or create a release.

## License

Copyright 2011 Tristan V. Gomez. This project is available under the GNU Lesser General Public License, version 3 or any later version. See [COPYING](COPYING).

The original API wrapper was forked from Hashrocket's `namecheap` project.
