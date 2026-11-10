# This repo's dev container

This is the dev container for working **on** the sandboxxer plugin. It is not a
template; the templates users get live in `skills/_shared/templates/`.

## Shared with the templates (do not copy)

| What | Source |
|---|---|
| `setup-claude-credentials.sh` | `skills/_shared/templates/setup-claude-credentials.sh`, run by `post-create.sh` |
| `sync-knowledge.sh` | `hooks/sync-knowledge.sh`, staged into `.devcontainer/` by `post-create.sh` (gitignored) |
| `fix-worktree-paths.sh` | `skills/_shared/templates/fix-worktree-paths.sh`, staged the same way (gitignored) |

Running the template directly means bugs in the shipped setup script reproduce
here, and fixes made here reach users (#389). Don't add a repo copy of these
files; `tests/unit/test_repo_devcontainer_single_source.bats` fails if one appears.

## Intentionally repo-specific

| File | Why it differs from the templates |
|---|---|
| `init-firewall.sh` | Permissive (no allowlist). This is a YOLO container for plugin development; the template's allowlist firewall would block the GitHub, npm and Docker Hub traffic the test suite and CI work need |
| `Dockerfile` | Adds the test tooling (`bats`, `file`, `yq`, #380) on top of the usual toolchain |
| `docker-compose.yml`, `devcontainer.json` | Mount the parent folder at `/workspace` and name the service/volumes for this repo |
| `post-create.sh` | The wrapper above |
