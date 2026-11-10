# Sandboxxer Roadmap

_Last evaluated: 2026-11-09 against v4.13.10 (`master` @ a74c970). Covered all 28 open issues at the time; #379–#381 were filed during the review._

Priorities follow the plugin's core promise: a **secure, reproducible, proxy-friendly sandbox**.
Security and correctness bugs in generated projects come before new features, because every
scaffolded project keeps the defect until the user regenerates it.

---

## Milestone 1 — v4.14 "Harden what we ship" (security + correctness)

Small, independent fixes. Each one changes generated templates, so each needs a BATS test that
fails on the old template.

| Issue | Work | Verified state | Size |
|---|---|---|---|
| #379 | **Close blanket SSH egress**: remove `iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT` or limit it to allowlisted git hosts | Still present: `skills/_shared/templates/init-firewall.sh:188` | S |
| #379 | **Drop `gist.github.com`** from the allowlist (paste-out channel) | Still present: `skills/_shared/templates/data/allowable-domains.json:30` | XS |
| #368 | **One source for `sync-knowledge.sh`**: make templates use the hardened `hooks/` copy (generate or copy at build time) and add a test that fails if the copies differ | Confirmed drift: `.devcontainer/` and template copies are identical to each other and differ from `hooks/` | S |
| #377 | **Host UID/GID at build time**: `ARG USER_UID/USER_GID` in `base.dockerfile`, pass through compose, write `id -u`/`id -g` to `.env` in quickstart and yolo-docker | Confirmed: `CONTAINER_UID` is read by 5 compose templates and set nowhere | M |
| #365 (reopened, fixed in 4.13.11) | **Safety hook never runs**: `hooks/docker-safety-hook.sh` is 100644 in git and `run-hook.cmd` runs it directly, so the PreToolUse:Bash hook fails with Permission denied. Run it with `bash` in the wrapper and set +x | Installed 4.13.10 cache has `-rw-r--r--` | XS |
| #380 | **Test runner skips 316 of 337 tests**: `bats tests/` only picks up `*.bats`, and the `*.test.sh` files are never run, locally or in CI. Switch to `bats -r` with explicit file lists, then fix about 34 failing tests (mostly out-of-date expectations: data-file schemas, sed moved from `.md` to `scripts/`, `((x++))` under `set -e`, `yq` not installed) | `npm run test:all` reports `1..0` and exits 0 | M |
| #364 | **Locale warning**: add `locales`, generate `en_US.UTF-8`, set `LANG`/`LC_ALL` in `base.dockerfile` (the issue names `.devcontainer/Dockerfile` and a `jedi-padawan` path, so move the target to the template) | No locale setup in `base.dockerfile` | XS |

Exit criteria: `npm run test:all` and `./scripts/doc-health-check.sh` pass, plus a CHANGELOG entry
that tells users to regenerate (or patch) existing `.devcontainer/` folders.

## Milestone 2 — v4.15 "Don't lose user data" (persistence + hooks)

These depend on Milestone 1. #366 and #378 need correct UIDs (#377) or the bind mounts get the
wrong owner. #369 should be built on the single `sync-knowledge.sh` from #368.

| Issue | Work | Depends on | Size |
|---|---|---|---|
| #366 | Bind-mount host `~/.claude/projects/` over the named volume so transcripts survive `docker volume prune` and rebuilds. Ship a one-time migration that copies existing `*_claude-data` volumes | #377 | M |
| #369 | Split SessionEnd from SessionStart: SessionEnd flushes only the current container (`sync`, scoped by container/volume ID), and the whole-host scan stays in SessionStart only | #368 | M |
| #378 | Prebuilt-image UID matching (recommended: thin local `FROM <prebuilt>` remap layer, which keeps the no-root-entrypoint posture) and narrow `safe.directory '*'` to the workspace folder (`devcontainer.json:71`) | #377 | S–M |

## Milestone 3 — v4.16 "Enterprise and CI" (proxy + quality gates)

| Issue | Work | Verified state | Size |
|---|---|---|---|
| #269 | Pass `HTTP(S)_PROXY`/`NO_PROXY` build args through `devcontainer.json` → compose → Dockerfile, and add proxy detection to `yolo-linux-maxxing` | Only the `INSTALL_SHELL_EXTRAS/INSTALL_DEV_TOOLS` switches exist; no proxy args | M |
| #276 | CI gaps: ShellCheck, JSON/YAML template lint, and a devcontainer build smoke test. Release automation can come later | `docs-validation.yml` already runs doc health, `bats tests/unit/` and `bats tests/integration/`; no lint or build job | S–M |
| #275 | Rest of the prebuilt images: multi-arch (amd64/arm64), semver tags, and decide whether the go/rust/full variants are worth maintaining | `prebuild-images.yml` already publishes `sandboxxer-base` with `latest`/sha/branch tags only, single arch | S |
| #272 | Add `docker scout` (primary) and `trivy` (offline fallback) scanning to `/sandboxxer:audit`, skipped cleanly when neither tool is installed | Not started | M |

## Milestone 4 — Features (pick by demand)

| Issue | Recommendation |
|---|---|
| #371 Cost preview in `/deploy-to-azure` | **Do it, but solve packaging first.** The estimator lives in the user's `~/.claude/skills`, not in the plugin. Make the step optional: detect the skill, skip with a hint if it's missing |
| #370 `reduce-sandbox-friction` skill | **Already exists as a user-scope skill.** Decide whether to bundle it in the plugin. It fits the "sandbox" brand but targets the Claude Code host sandbox, not devcontainers. If bundled, move it with its tests |
| #273 RHEL/Fedora for yolo-linux | Reasonable: a `dnf` path plus SELinux notes. Detection already exits with "not supported". Wait for user demand |
| #242 Tailscale | **Partly delivered** (`partials/tailscale.dockerfile`, `docs/TAILSCALE-SETUP.md`). Narrow the issue to the sidecar-compose option or close it |

## Strategic / needs design

| Issue | Recommendation |
|---|---|
| #372 Autonomous feature-build pipeline | Ship the two security fixes in Milestone 1 now. The rest (jobs Bicep module, host/language adapters) needs its design doc in the repo: the referenced `docs/2026-07-09-portable-feature-build-plan.md` does not exist. Overlaps with the `ultrathink-autodev-maxxing` skill, so settle which project owns it |
| #381 Session orchestration (an orchestrator session starts worker sessions, each with its own sub-agents) | Umbrella feature with three backends behind one task format: **local worktrees** (one container), **local containers** (one per session), and **Azure Container Apps jobs** for long or resource-heavy sessions. #372 becomes the Azure backend. Needs #366, #368, #369 and #377 first. See the design notes in the issue |
| #274 MCP server | Defer. High effort, unclear consumer. Revisit if another plugin or a CI pipeline needs to call sandboxxer programmatically |
| #376 Canonical Workshop backend | Watch. Recheck in about 6 months for WSL2 support and egress controls, as the issue's own assessment says |

## Closed during review (2026-11-09)

Closed with a comment on each issue: #201 as completed, the rest as not planned. #365 was closed, then reopened when the hook turned out not to be executable, and is fixed in 4.13.11 (see M1).

| Issue | Reason |
|---|---|
| #201 Rename scripts + Windows | Renames already happened (`yolo-linux-maxxing`, `quickstart`). Close, or reframe as "native Windows (non-WSL) setup" if wanted |
| #363 LangSmith CLI | `curl … \| sh` breaks the proxy-friendly design. Close, or offer it as an opt-in partial (`INSTALL_LANGSMITH=false` by default) |
| #8 Serena | Stale (Dec 2025, windows-sandbox era). Close, or turn into an optional MCP/partial if anyone asks |
| #9 Corporate proxy case study | Solved by the multi-stage builds and `INSTALL_CA_CERT`. Move the useful parts to `docs/examples/` and close |
| #213 WSL screenshot workflow | Host-side personal tooling, not sandbox scope. Move to a gist/docs note and close |
| #298–#302 "Radical idea" docs proposals | Icebox. One cheap piece from #302 is worth taking: generate the command reference from command frontmatter inside `doc-health-check.sh`. Close the rest with an `icebox` label |

---

## Dependency graph

```
#379 (firewall), #365 (hook exec), #380 (test runner) ──► M1, no dependencies
#368 (single sync-knowledge) ──► #369 (SessionEnd flush)
#377 (host UID) ──┬──► #366 (bind-mount projects/)
                  └──► #378 (prebuilt UID + safe.directory)
#275 (prebuilt images) ──► #378
#380 (test runner) ──► #276 (CI lint/build): every later milestone relies on the suite actually running
M1 + #366 + #368 + #369 + #377 ──► #381 (orchestration) ──► #372 (Azure Container Apps backend)
```

## Summary

- **At review time, 28 open**: 11 closed (#365 later reopened and fixed), 3 filed (#379 firewall, #380 test runner, #381 orchestration), and #372 narrowed to the Azure Container Apps backend of #381.
- **Most urgent**: the SSH egress hole and gist exfiltration in the firewall (#379), and the unhardened `sync-knowledge.sh` that ships into every scaffolded project (#368).
- **Biggest user-visible fix**: #377 (UID mismatch on macOS and enterprise hosts), which also unblocks #366 and #378.
