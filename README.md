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

Applications can select the Namecheap environment independently of `RACK_ENV`
or `Rails.env`. This is useful when a staging application runs in production
mode but must continue using Namecheap's sandbox:

```ruby
Namecheap.configure do |config|
  config.environment = "sandbox"
end
```

Set `environment` to either `"sandbox"` or `"production"`. Leave it unset, or
set it to `nil`, to retain automatic Rails/Rack environment selection.

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
  environment: sandbox
```

```ruby
Namecheap::Config.load!("config/namecheap.yml")
```

## Development

Install dependencies and run the test and style checks:

```shell
mise exec -- bundle install
mise exec -- bundle exec rake
```

Build a local gem without publishing it:

```shell
mise exec -- bundle exec gem build namecheap.gemspec
```

### Manual release

Releases from this legacy branch are intentionally manual. Start from a clean
`legacy/0.3` checkout and confirm that `lib/namecheap/version.rb` and the dated
changelog heading contain the same version. Then run:

```shell
mise exec -- bundle install
mise exec -- bundle exec rake
mise exec -- bundle exec gem build namecheap.gemspec
mise exec -- ruby -rrubygems/package -e \
  'spec = Gem::Package.new(ARGV.fetch(0)).spec; puts "#{spec.name} #{spec.version} (Ruby #{spec.required_ruby_version})"' \
  namecheap-0.3.1.gem
```

Commit and push the finalized release changes before creating a signed,
annotated tag for the exact release commit:

```shell
git tag -s v0.3.1 -m "Release 0.3.1"
git push origin legacy/0.3
git push origin v0.3.1
```

Publish the artifact to RubyGems manually. RubyGems may prompt for MFA:

```shell
mise exec -- gem push namecheap-0.3.1.gem
```

After RubyGems reports version 0.3.1 as published, create the corresponding
GitHub Release:

```shell
gh release create v0.3.1 --verify-tag --generate-notes --title v0.3.1
```

Changing the version, building the gem, or pushing the branch does not publish
a release.

## License

Copyright 2011 Tristan V. Gomez. This project is available under the GNU Lesser General Public License, version 3 or any later version. See [COPYING](COPYING).

The original API wrapper was forked from Hashrocket's `namecheap` project.
