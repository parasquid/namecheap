# Changelog

## 2.0.0.pre1 (unreleased)

- Require Ruby 3.3 or newer and add CI for Ruby 3.3, 3.4, and 4.0.
- Require a Namecheap-whitelisted client IP when constructing a client.
- Make client configuration private and immutable, validate its public inputs,
  and reject protected authentication parameters before requests.
- Complete the 0.3.1 domain and DNS command coverage using explicit v2 resource methods.
- Add structured contact, email-forwarding, and DNS-record payloads with request validation.
- Use form-encoded POST requests for domain creation and DNS host replacement.
- Add deterministic request tests, Standard Ruby checks, and modern gem metadata.
- Add `users.getPricing` support for exact domain registration and renewal quotes.
- Add an agent-discoverable CLI with XDG profiles, env-file configuration, human/JSON/raw output, guarded paid actions, and drift-safe DNS record workflows.
- Reach current-adjusted 0.3.1 command parity with registered nameserver, transfer, SSL, user, and domain-privacy resources.
- Expose every API operation through the CLI, including structured private input for secrets and guarded unquotable charges.
- Redact API keys, passwords, transfer and reset codes, and tokens consistently
  across CLI responses, raw XML, previews, profiles, and errors.
- Cover all 59 commands in Namecheap's current API catalog, including user addresses and the latest SSL operations.
- Return normalized response objects with raw XML access and raise typed API, transport, and parse errors.
- Add configurable open and read timeouts and reuse one Faraday connection
  across each client's resources.
- Add verified, signed-tag release automation using RubyGems trusted publishing.
- Promote v2 development to `main` and preserve the old 0.3 line as `legacy/0.3`.

This prerelease has not been published. Open GitHub
[issues](https://github.com/parasquid/namecheap/issues) are the live roadmap.
The planned 0.3-to-v2 migration guide is tracked in
[issue #18](https://github.com/parasquid/namecheap/issues/18).
