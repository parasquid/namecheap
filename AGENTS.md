# Repository Guidelines

## Project Structure & Module Organization

The `main` branch contains the experimental v2 client. The public entrypoint is `lib/namecheap.rb`; active code lives under `lib/namecheap/api/`. `Client` owns configuration, resource classes expose commands, and `Base` handles URLs and Faraday requests.

Older 0.3.x files remain directly under `lib/namecheap/` for reference and the
former release line is preserved on `legacy/0.3`; neither is part of active
development. Do not extend or require the legacy files. Tests mirror the active
namespace under `spec/namecheap/api/`.

## Build, Test, and Development Commands

Use [mise](https://mise.jdx.dev/) for the Ruby toolchain. The repository's
`.ruby-version` is the version source of truth. For a new environment:

```shell
curl https://mise.run | sh
mise settings add idiomatic_version_file_enable_tools ruby
MISE_RUBY_COMPILE=false mise install ruby
mise exec -- ruby -v
```

`MISE_RUBY_COMPILE=false` selects mise's verified precompiled Ruby when
available and avoids requiring local compiler headers. Run repository commands
through `mise exec --` so they use the pinned Ruby even when shell activation is
not configured.

- `mise exec -- bundle install`: install runtime and development dependencies.
- `mise exec -- bundle exec rake`: run the complete RSpec and Standard Ruby checks.
- `mise exec -- bundle exec rspec`: run tests only; pass a file path to focus a run.
- `mise exec -- bundle exec standardrb`: check formatting and style without rewriting files.
- `mise exec -- bundle exec gem build namecheap.gemspec`: build the unreleased prerelease locally.

## Coding Style & Naming Conventions

Use two-space indentation and Standard Ruby conventions. Classes use `CamelCase`; files, methods, and variables use `snake_case`. Preserve the `Namecheap::API` namespace. Before changing Ruby code, read [docs/standards/coding-style-conventions.md](docs/standards/coding-style-conventions.md). It defines the required resource-method pattern, parameter precedence, transport boundaries, testing contract, and completion checklist.

## Testing Guidelines

Use RSpec and name files `*_spec.rb`. Every resource method needs request-contract coverage for its command, endpoint, parameters, and response body. WebMock must block real network access. Test invalid configuration and protected parameters when changing shared code. CI covers Ruby 3.3, 3.4, and 4.0.

Keep both sandbox smoke surfaces current. When adding or changing an API command, update `script/sandbox_smoke` as applicable. When adding or changing a CLI command, update `script/cli_sandbox_smoke` in the same change. Default smoke runs must remain read-only or use `--dry-run`; put persistent writes behind an explicit lifecycle option.

Treat the Ruby API and CLI as one public feature surface. Every new or changed
resource method must add or update its explicit CLI catalog entry, dispatch,
machine-readable help, input example or schema where applicable, deterministic
CLI tests, and safe smoke coverage in the same change. Only omit CLI exposure
when the user explicitly excludes it or the upstream operation cannot be made
safe; document any exception beside the command coverage.

## Roadmap

GitHub open issues are the project roadmap. Before proposing new work or
selecting the next task, review the repository's open issues. Keep planned work
represented by focused issues rather than maintaining a separate roadmap
document.

## Commit & Pull Request Guidelines

Use short, imperative subjects such as `Modernize v2 prototype`. Keep commits focused. Pull requests should explain behavior, incomplete API areas, and validation; link issues when available.

Name branches using lowercase kebab case. Do not add type, username, or agent
prefixes. Issue numbers are encouraged for traceability, not required. Use this
sequence when choosing a branch name:

1. Check whether the task has a parent issue.
2. Before making file changes for work tied to a GitHub issue, check the current
   branch and existing local branches. If the current branch is unrelated but a
   matching issue branch already exists, treat the work as a possible
   continuation and switch to that branch. If no matching branch exists, ask
   the user whether to create an issue branch before editing.
3. When a parent issue exists, encourage
   `<issue-number>-<short-description>`, such as `19-request-timeouts`.
4. When no parent issue exists, recommend creating one for traceability.
5. If the user prefers not to create an issue, respect that decision and use a
   concise descriptive name such as `refresh-readme-examples`.
6. Respect an explicit branch name chosen by the user.
7. After a topic branch has been merged, offer to delete both its local and
   remote copies. Do not delete either branch without the user's confirmation.

## Remote Completion Gate

For pull-request work, a successful local test run, commit, push, or PR creation
does not constitute completion. After every push, inspect and wait for all
required PR checks to reach a terminal state. If any check fails, inspect its
logs, fix the cause, push the correction, and repeat.

Report work as complete only when the remote branch contains the intended
commit, every required check is present and green, and the PR diff contains only
the intended files. While checks are pending, report the work as pending rather
than complete.

## Security & Releases

Never commit API keys, usernames, client IP configuration, or environment files containing credentials. Manual staging tests must load sandbox credentials from `.env.staging`; never use production credentials for them. Version changes, branch pushes, and gem builds do not constitute a release. A release requires a finalized changelog entry and an annotated signed `vVERSION` tag from `main` that GitHub reports as verified. Pushing that tag runs the release workflow, which validates the tag and publishes through RubyGems trusted publishing without a long-lived API key.

CLI commands must never accept durable secrets such as API keys, passwords, or
transfer authorization codes as command-line values, because process listings
and shell logs can expose them. Use no-echo prompts for interactive entry and
permission-checked files or standard input for automation. Never render secrets
in previews, errors, JSON, examples, or logs. Short-lived or one-time tokens may
be command arguments when the usability benefit justifies it, but must still be
redacted from output.

Paid CLI commands require an exact API quote before execution when Namecheap
offers one. If no quote API exists, require an explicit expected amount and
currency, warn that Namecheap cannot enforce the amount as a transactional
ceiling, and compare the returned charge after execution.
