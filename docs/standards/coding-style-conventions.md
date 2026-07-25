# Coding Style and Conventions

This document defines the implementation contract for the experimental v2 client on `main`. Follow it for all active code under `lib/namecheap/api/` and its tests. Older 0.3.x files directly under `lib/namecheap/` and the `legacy/0.3` branch are retained only for reference; do not modify, require, package, or imitate them.

## Architecture Boundaries

- `Namecheap::API::Client` validates account configuration and exposes top-level resources.
- Resource classes model Namecheap command groups. Nest resources when the upstream hierarchy does, for example `client.domains.dns`.
- `Namecheap::API::Base` owns endpoints, authentication request fields, URL construction, and Faraday calls.
- Resource classes must not call Faraday, select environments, or duplicate authentication logic.
- Keep the public API instance-based. Do not introduce global configuration or singleton resources.

## Resource Methods

Write one explicit Ruby method per documented Namecheap command. Do not generate methods from a catalog or use `method_missing`.

Use `snake_case` Ruby names and preserve the exact upstream command string:

```ruby
def get_info(domain_name:, params: {})
  command = "namecheap.domains.getInfo"
  params = params.merge("DomainName" => domain_name)
  build_and_get(command, params)
end
```

Required upstream parameters must be required keyword arguments. Accept optional and newly added upstream fields through a final `params: {}` keyword. Use Namecheap's exact parameter casing inside request hashes, such as `"DomainName"`, `"CertificateID"`, and `"TransferID"`.

When a command repeats a structured group, use a required hash or array keyword rather than an excessively long flat signature. Structured inputs use snake-case keys, validate required and unknown fields before a request, and serialize to exact upstream names. For example, contact groups use `registrant:` and `tech:` hashes, while numbered DNS fields use a `records:` array. Leave uncommon or TLD-specific fields in `params`.

Merge required fields after caller-supplied parameters so callers cannot replace them. `Base` must continue merging authentication and `Command` last. Never allow `params` to override `ApiUser`, `ApiKey`, `UserName`, `ClientIp`, or `Command`.

Use the HTTP method recommended by Namecheap's current documentation. Extend shared transport helpers in `Base` when POST support is needed; do not implement transport locally in a resource.

POST commands send form-encoded request parameters rather than moving the same payload into a query string. Document replace-all commands prominently; callers must not mistake a partial payload for a patch.

## Resource Accessors

Expose implemented resources from `Client` or their documented parent resource. An accessor returns the corresponding resource object configured with the same client configuration. Until a resource is implemented, keep an explicit `NotImplementedError`; never return `nil` for advertised functionality.

Do not silently add compatibility aliases from the 0.3.x API. Any alias or public naming change requires documentation and dedicated tests.

## Responses and Errors

All resource methods return `Namecheap::API::Response`. The shared parser normalizes result keys to snake-case symbols while retaining the exact upstream body as `raw_body`. Keep parsing centralized and namespace-agnostic; do not introduce command-specific response objects.

Namecheap error envelopes raise `Namecheap::API::ApiError`. HTTP and network failures raise `TransportError`, and empty or malformed XML raises `ParseError`. Errors expose safe command and response metadata without authenticated URLs or secret request fields.

Configuration mistakes should fail before a request. Error messages must identify the invalid field. Never include API keys or other secrets in exceptions, logs, fixtures, or inspected URLs.

## CLI Commands

CLI code lives under `lib/namecheap/cli/`, with `exe/namecheap` as its only executable entrypoint. Keep routing and execution explicit: the command catalog is the shared source for help, examples, and machine-readable discovery, but must not dynamically generate API calls.

Every public command must appear in `Catalog`, support `namecheap help PATH --json`, and remain discoverable without loading config, credentials, or the network. Structured examples emitted by `--example` must be accepted by the same input validation used during execution.

Every public resource method must have corresponding CLI coverage in the same
change unless the user explicitly excludes it or the upstream operation cannot
be exposed safely. CLI coverage includes an explicit catalog route and dispatch,
machine-readable help, deterministic tests, an input schema/example when
structured data is required, and applicable safe smoke coverage.

Update `script/cli_sandbox_smoke` whenever a CLI command is added or its syntax, output contract, or safety behavior changes. Exercise new read commands directly and mutation commands with `--dry-run` by default. If the sandbox cannot exercise a command, document the reason beside the smoke coverage and retain deterministic RSpec coverage. Keep `script/sandbox_smoke` updated independently for direct Ruby API coverage.

Write normal results to stdout and prompts or errors to stderr. Preserve the JSON envelope (`data` and `meta`) and documented exit codes. Never accept an API key as a command-line option. Respect precedence in this order: command-line selectors, explicit env file, process environment, selected XDG profile, then sandbox defaults.

All mutating commands support `--dry-run` and confirmation. Paid commands require an exact API quote. DNS record helpers must read the full zone, preview changes, re-read to detect drift, submit a complete replacement, and verify it afterward.

Never accept durable secrets as command-line values. Prompt without echo for
interactive use and use private input files or standard input for automation.
Redact secret fields recursively from all previews and output. Short-lived or
one-time tokens may be arguments only when explicitly justified and must still
be redacted. When an upstream paid operation has no quote API, require an
expected amount and currency, warn that the amount cannot be enforced before
the charge, and compare it with the returned charge.

## Tests

Every resource method requires deterministic RSpec request-contract coverage. Use WebMock and assert:

- sandbox or production endpoint;
- exact `Command` value;
- HTTP method, parameter location, authentication, and required request parameters;
- representative optional parameters;
- protected-field precedence;
- raw response body returned to the caller.

Real network access is forbidden in the unit suite. Use documentation-safe values such as `192.0.2.1`, `example.com`, and obviously fake credentials. Add construction and `NotImplementedError` tests for resource accessors.

Keep staging tests opt-in and separate from the unit suite. They must load sandbox-only credentials from the ignored `.env.staging` file, refuse production environments, and avoid printing API keys or complete authenticated request URLs.

## Style and Completion Checklist

Use two-space indentation, `CamelCase` constants, `snake_case` methods, double-quoted strings, and Standard Ruby formatting. Keep methods small and use descriptive local names; comments should explain upstream quirks rather than restate code.

Before considering a change complete:

1. Run `bundle exec rake`.
2. Build with `bundle exec gem build namecheap.gemspec`.
3. Confirm new active files are included in `spec.files` and legacy files remain excluded.
4. Update README and changelog when public behavior or implemented command coverage changes.
5. Verify CI on Ruby 3.3, 3.4, and 4.0.

Version changes and successful builds do not publish a release. After finalizing
the changelog on `main`, create and push an annotated signed `vVERSION` tag that
GitHub reports as verified. The release workflow validates that tag, re-runs the
full checks, publishes through RubyGems trusted publishing, and creates the
matching GitHub Release.
