# Changelog

## 2.0.0.pre (unreleased)

- Require Ruby 3.3 or newer and add CI for Ruby 3.3, 3.4, and 4.0.
- Require a Namecheap-whitelisted client IP when constructing a client.
- Validate client configuration and protect authentication parameters from overrides.
- Make unfinished API resources fail explicitly with `NotImplementedError`.
- Complete the 0.3.1 domain and DNS command coverage using explicit v2 resource methods.
- Add structured contact, email-forwarding, and DNS-record payloads with request validation.
- Use form-encoded POST requests for domain creation and DNS host replacement.
- Add deterministic request tests, Standard Ruby checks, and modern gem metadata.
- Add `users.getPricing` support for exact domain registration and renewal quotes.
- Add an agent-discoverable CLI with XDG profiles, env-file configuration, human/JSON/raw output, guarded paid actions, and drift-safe DNS record workflows.

This prerelease remains incomplete and is not published automatically.
