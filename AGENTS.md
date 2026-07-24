# Repository Guidelines

## Project Structure & Module Organization

This branch contains the experimental v2 client. The public entrypoint is `lib/namecheap.rb`; active code lives under `lib/namecheap/api/`. `Client` owns configuration, resource classes expose commands, and `Base` handles URLs and Faraday requests.

Older 0.3.x files remain directly under `lib/namecheap/` for reference but are excluded from the v2 gem. Do not extend or require them. Tests mirror the active namespace under `spec/namecheap/api/`.

## Build, Test, and Development Commands

- `bundle install`: install runtime and development dependencies.
- `bundle exec rake`: run the complete RSpec and Standard Ruby checks.
- `bundle exec rspec`: run tests only; pass a file path to focus a run.
- `bundle exec standardrb`: check formatting and style without rewriting files.
- `bundle exec gem build namecheap.gemspec`: build the unreleased prerelease locally.

## Coding Style & Naming Conventions

Use two-space indentation and Standard Ruby conventions. Classes use `CamelCase`; files, methods, and variables use `snake_case`. Preserve the `Namecheap::API` namespace. Before changing Ruby code, read [docs/standards/coding-style-conventions.md](docs/standards/coding-style-conventions.md). It defines the required resource-method pattern, parameter precedence, transport boundaries, testing contract, and completion checklist.

## Testing Guidelines

Use RSpec and name files `*_spec.rb`. Every resource method needs request-contract coverage for its command, endpoint, parameters, and response body. WebMock must block real network access. Test invalid configuration and protected parameters when changing shared code. CI covers Ruby 3.3, 3.4, and 4.0.

## Commit & Pull Request Guidelines

Use short, imperative subjects such as `Modernize v2 prototype`. Keep commits focused. Pull requests should explain behavior, incomplete API areas, and validation; link issues when available.

## Security & Releases

Never commit API keys, usernames, client IP configuration, or environment files containing credentials. Manual staging tests must load sandbox credentials from `.env.staging`; never use production credentials for them. Version changes, branch pushes, and gem builds do not constitute a release; tagging and RubyGems publication are separate manual actions.
