# LOG791 — Programming learning and assessment platform

A platform where students write, run and submit code that is judged in an isolated sandbox, built first for LOG200 at ÉTS. The architecture, the ADRs and the project plan are published at <https://vianpyro.github.io/LOG791/>; their sources are in [`docs/`](docs/).

## Getting started

Everything runs in the dev container: Python 3.14, uv, PostgreSQL, a local LDAP directory, Docker with gVisor, Typst and Ansible.

1. Open the repository in VS Code and choose **Reopen in Container** (Docker required).
2. Wait for the first build. It installs the Python workspace (`uv sync`), then `check.sh` prints one line per service; every line should read `ok`.
3. Run the architecture check: `uv run lint-imports`.

Common commands are VS Code tasks (**Tasks: Run Task**):

| Task | What it does |
|------|--------------|
| `python: sync` | Install the locked dependencies after a pull |
| `architecture: check` | Check component boundaries, as CI does |
| `env: check` | Check that every local service answers |
| `docs: build site` | Build every document into `_site/` |
| `db: psql` | Open a shell on the local database |
| `gvisor: sandbox shell` | A shell in a gVisor sandbox with no network |

Test accounts for the local directory are in [`.devcontainer/ldap/`](.devcontainer/ldap/); the lldap admin interface is forwarded on port 17170.

Outside the dev container, install [uv](https://docs.astral.sh/uv/) and run `uv sync`; the services and gVisor are then yours to provide.

## Layout

| Path | Contents |
|------|----------|
| `apps/` | `api`, `judge`, `publisher`, `admin` (Python) and `web` (static) |
| `packages/` | Code shared by the apps: `contracts` (JSON Schemas), `content` (release reader, opening rule) |
| `packs/` | Language packs, test runners and question types: data, not core code |
| `db/migrations/` | PostgreSQL schema |
| `infrastructure/ansible/` | Machine configuration and operations |
| `tests/` | Cross-component tests: architecture, conformance, load |
| `spikes/` | Throwaway study code, deleted once its ADR is decided |
| `docs/`, `report/`, `site/` | Architecture, ADRs, project plan, final report, documentation site |

The full description is in the *Code organization* section of the architecture document.

## Rules

- The API and the judge never import each other, and `packages/` imports no app. `lint-imports` checks this in CI (ADR-0014).
- A language, a course or a question type is added as data under `packs/` or in content, never as a special case in the core.
- An accepted ADR is never edited: a new ADR supersedes it. A new ADR is also listed in [`docs/adr/index.typ`](docs/adr/index.typ).
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (see [`.copilot/commit-message-instructions.md`](.copilot/commit-message-instructions.md)).
