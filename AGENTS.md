# Repository Guidelines

## Before Starting Any New Feature

**Stop and research before coding.** When implementing a new feature or modifying existing functionality:

1. **Identify the relevant subsystem** - Check the sections below (e.g., "Model Selection and Alias System") for documented architecture
2. **Read the key source files** - Each section lists the files involved; read them to understand existing patterns
3. **Understand the data flow** - Trace how data moves through the system before proposing changes
4. **Work WITH the architecture** - If something seems hard, you're probably fighting the design. Ask yourself: "Is there an existing mechanism for this?" (e.g., config allowlists, alias indexes, session persistence)
5. **Verify external dependencies** - For third-party APIs, check their actual documentation for correct endpoints/model IDs; don't assume based on naming conventions

**Common mistakes to avoid:**

- Adding code to bypass existing validation (allowlists, permissions) instead of using proper config
- Assuming external API model IDs match HuggingFace/marketing names
- Making changes without reading the files that will be affected
- Proposing "V2" copies instead of extending existing patterns

---

- Repo: https://github.com/openclaw/openclaw
- GitHub issues/comments/PR comments: use literal multiline strings or `-F - <<'EOF'` (or $'...') for real newlines; never embed "\\n".

## Project Structure & Module Organization

- Source code: `src/` (CLI wiring in `src/cli`, commands in `src/commands`, web provider in `src/provider-web.ts`, infra in `src/infra`, media pipeline in `src/media`).
- Tests: colocated `*.test.ts`.
- Docs: `docs/` (images, queue, Pi config). Built output lives in `dist/`.
- Plugins/extensions: live under `extensions/*` (workspace packages). Keep plugin-only deps in the extension `package.json`; do not add them to the root `package.json` unless core uses them.
- Plugins: install runs `npm install --omit=dev` in plugin dir; runtime deps must live in `dependencies`. Avoid `workspace:*` in `dependencies` (npm install breaks); put `openclaw` in `devDependencies` or `peerDependencies` instead (runtime resolves `openclaw/plugin-sdk` via jiti alias).
- Installers served from `https://openclaw.ai/*`: live in the sibling repo `../openclaw.ai` (`public/install.sh`, `public/install-cli.sh`, `public/install.ps1`).
- Messaging channels: always consider **all** built-in + extension channels when refactoring shared logic (routing, allowlists, pairing, command gating, onboarding, docs).
  - Core channel docs: `docs/channels/`
  - Core channel code: `src/telegram`, `src/discord`, `src/slack`, `src/signal`, `src/imessage`, `src/web` (WhatsApp web), `src/channels`, `src/routing`
  - Extensions (channel plugins): `extensions/*` (e.g. `extensions/msteams`, `extensions/matrix`, `extensions/zalo`, `extensions/zalouser`, `extensions/voice-call`)
- When adding channels/extensions/apps/docs, update `.github/labeler.yml` and create matching GitHub labels (use existing channel/extension label colors).

## Docs Linking (Mintlify)

- Docs are hosted on Mintlify (docs.openclaw.ai).
- Internal doc links in `docs/**/*.md`: root-relative, no `.md`/`.mdx` (example: `[Config](/configuration)`).
- When working with documentation, read the mintlify skill.
- Section cross-references: use anchors on root-relative paths (example: `[Hooks](/configuration#hooks)`).
- Doc headings and anchors: avoid em dashes and apostrophes in headings because they break Mintlify anchor links.
- When Peter asks for links, reply with full `https://docs.openclaw.ai/...` URLs (not root-relative).
- When you touch docs, end the reply with the `https://docs.openclaw.ai/...` URLs you referenced.
- README (GitHub): keep absolute docs URLs (`https://docs.openclaw.ai/...`) so links work on GitHub.
- Docs content must be generic: no personal device names/hostnames/paths; use placeholders like `user@gateway-host` and “gateway host”.

## Docs i18n (zh-CN)

- `docs/zh-CN/**` is generated; do not edit unless the user explicitly asks.
- Pipeline: update English docs → adjust glossary (`docs/.i18n/glossary.zh-CN.json`) → run `scripts/docs-i18n` → apply targeted fixes only if instructed.
- Translation memory: `docs/.i18n/zh-CN.tm.jsonl` (generated).
- See `docs/.i18n/README.md`.
- The pipeline can be slow/inefficient; if it’s dragging, ping @jospalmbier on Discord instead of hacking around it.

## exe.dev VM ops (general)

- Access: stable path is `ssh exe.dev` then `ssh vm-name` (assume SSH key already set).
- SSH flaky: use exe.dev web terminal or Shelley (web agent); keep a tmux session for long ops.
- Update: `sudo npm i -g openclaw@latest` (global install needs root on `/usr/lib/node_modules`).
- Config: use `openclaw config set ...`; ensure `gateway.mode=local` is set.
- Discord: store raw token only (no `DISCORD_BOT_TOKEN=` prefix).
- Restart: stop old gateway and run:
  `pkill -9 -f openclaw-gateway || true; nohup openclaw gateway run --bind loopback --port 18789 --force > /tmp/openclaw-gateway.log 2>&1 &`
- Verify: `openclaw channels status --probe`, `ss -ltnp | rg 18789`, `tail -n 120 /tmp/openclaw-gateway.log`.

## Build, Test, and Development Commands

- Runtime baseline: Node **22+** (keep Node + Bun paths working).
- Install deps: `pnpm install`
- Pre-commit hooks: `prek install` (runs same checks as CI)
- Also supported: `bun install` (keep `pnpm-lock.yaml` + Bun patching in sync when touching deps/patches).
- Prefer Bun for TypeScript execution (scripts, dev, tests): `bun <file.ts>` / `bunx <tool>`.
- Run CLI in dev: `pnpm openclaw ...` (bun) or `pnpm dev`.
- Node remains supported for running built output (`dist/*`) and production installs.
- Mac packaging (dev): `scripts/package-mac-app.sh` defaults to current arch. Release checklist: `docs/platforms/mac/release.md`.
- Type-check/build: `pnpm build`
- TypeScript checks: `pnpm tsgo`
- Lint/format: `pnpm check`
- Format check: `pnpm format` (oxfmt --check)
- Format fix: `pnpm format:fix` (oxfmt --write)
- Tests: `pnpm test` (vitest); coverage: `pnpm test:coverage`

## Coding Style & Naming Conventions

- Language: TypeScript (ESM). Prefer strict typing; avoid `any`.
- Formatting/linting via Oxlint and Oxfmt; run `pnpm check` before commits.
- Add brief code comments for tricky or non-obvious logic.
- Keep files concise; extract helpers instead of “V2” copies. Use existing patterns for CLI options and dependency injection via `createDefaultDeps`.
- Aim to keep files under ~700 LOC; guideline only (not a hard guardrail). Split/refactor when it improves clarity or testability.
- Naming: use **OpenClaw** for product/app/docs headings; use `openclaw` for CLI command, package/binary, paths, and config keys.

## Release Channels (Naming)

- stable: tagged releases only (e.g. `vYYYY.M.D`), npm dist-tag `latest`.
- beta: prerelease tags `vYYYY.M.D-beta.N`, npm dist-tag `beta` (may ship without macOS app).
- dev: moving head on `main` (no tag; git checkout main).

## Testing Guidelines

- Framework: Vitest with V8 coverage thresholds (70% lines/branches/functions/statements).
- Naming: match source names with `*.test.ts`; e2e in `*.e2e.test.ts`.
- Run `pnpm test` (or `pnpm test:coverage`) before pushing when you touch logic.
- Do not set test workers above 16; tried already.
- Live tests (real keys): `CLAWDBOT_LIVE_TEST=1 pnpm test:live` (OpenClaw-only) or `LIVE=1 pnpm test:live` (includes provider live tests). Docker: `pnpm test:docker:live-models`, `pnpm test:docker:live-gateway`. Onboarding Docker E2E: `pnpm test:docker:onboard`.
- Full kit + what’s covered: `docs/testing.md`.
- Pure test additions/fixes generally do **not** need a changelog entry unless they alter user-facing behavior or the user asks for one.
- Mobile: before using a simulator, check for connected real devices (iOS + Android) and prefer them when available.

## Commit & Pull Request Guidelines

**Full maintainer PR workflow:** `.agents/skills/PR_WORKFLOW.md` -- triage order, quality bar, rebase rules, commit/changelog conventions, co-contributor policy, and the 3-step skill pipeline (`review-pr` > `prepare-pr` > `merge-pr`).

- Create commits with `scripts/committer "<msg>" <file...>`; avoid manual `git add`/`git commit` so staging stays scoped.
- Follow concise, action-oriented commit messages (e.g., `CLI: add verbose flag to send`).
- Group related changes; avoid bundling unrelated refactors.
- Read this when submitting a PR: `docs/help/submitting-a-pr.md` ([Submitting a PR](https://docs.openclaw.ai/help/submitting-a-pr))
- Read this when submitting an issue: `docs/help/submitting-an-issue.md` ([Submitting an Issue](https://docs.openclaw.ai/help/submitting-an-issue))

## Shorthand Commands

- `sync`: if working tree is dirty, commit all changes (pick a sensible Conventional Commit message), then `git pull --rebase`; if rebase conflicts and cannot resolve, stop; otherwise `git push`.

## Security & Configuration Tips

- Web provider stores creds at `~/.openclaw/credentials/`; rerun `openclaw login` if logged out.
- Pi sessions live under `~/.openclaw/sessions/` by default; the base directory is not configurable.
- Environment variables: see `~/.profile`.
- Never commit or publish real phone numbers, videos, or live configuration values. Use obviously fake placeholders in docs, tests, and examples.
- Release flow: always read `docs/reference/RELEASING.md` and `docs/platforms/mac/release.md` before any release work; do not ask routine questions once those docs answer them.

## Troubleshooting

- Rebrand/migration issues or legacy config/service warnings: run `openclaw doctor` (see `docs/gateway/doctor.md`).

## Agent-Specific Notes

- Vocabulary: "makeup" = "mac app".
- Never edit `node_modules` (global/Homebrew/npm/git installs too). Updates overwrite. Skill notes go in `tools.md` or `AGENTS.md`.
- When adding a new `AGENTS.md` anywhere in the repo, also add a `CLAUDE.md` symlink pointing to it (example: `ln -s AGENTS.md CLAUDE.md`).
- Signal: "update fly" => `fly ssh console -a flawd-bot -C "bash -lc 'cd /data/clawd/openclaw && git pull --rebase origin main'"` then `fly machines restart e825232f34d058 -a flawd-bot`.
- When working on a GitHub Issue or PR, print the full URL at the end of the task.
- When answering questions, respond with high-confidence answers only: verify in code; do not guess.
- Never update the Carbon dependency.
- Any dependency with `pnpm.patchedDependencies` must use an exact version (no `^`/`~`).
- Patching dependencies (pnpm patches, overrides, or vendored changes) requires explicit approval; do not do this by default.
- CLI progress: use `src/cli/progress.ts` (`osc-progress` + `@clack/prompts` spinner); don’t hand-roll spinners/bars.
- Status output: keep tables + ANSI-safe wrapping (`src/terminal/table.ts`); `status --all` = read-only/pasteable, `status --deep` = probes.
- Gateway currently runs only as the menubar app; there is no separate LaunchAgent/helper label installed. Restart via the OpenClaw Mac app or `scripts/restart-mac.sh`; to verify/kill use `launchctl print gui/$UID | grep openclaw` rather than assuming a fixed label. **When debugging on macOS, start/stop the gateway via the app, not ad-hoc tmux sessions; kill any temporary tunnels before handoff.**
- macOS logs: use `./scripts/clawlog.sh` to query unified logs for the OpenClaw subsystem; it supports follow/tail/category filters and expects passwordless sudo for `/usr/bin/log`.
- If shared guardrails are available locally, review them; otherwise follow this repo's guidance.
- SwiftUI state management (iOS/macOS): prefer the `Observation` framework (`@Observable`, `@Bindable`) over `ObservableObject`/`@StateObject`; don’t introduce new `ObservableObject` unless required for compatibility, and migrate existing usages when touching related code.
- Connection providers: when adding a new connection, update every UI surface and docs (macOS app, web UI, mobile if applicable, onboarding/overview docs) and add matching status + configuration forms so provider lists and settings stay in sync.
- Version locations: `package.json` (CLI), `apps/android/app/build.gradle.kts` (versionName/versionCode), `apps/ios/Sources/Info.plist` + `apps/ios/Tests/Info.plist` (CFBundleShortVersionString/CFBundleVersion), `apps/macos/Sources/OpenClaw/Resources/Info.plist` (CFBundleShortVersionString/CFBundleVersion), `docs/install/updating.md` (pinned npm version), `docs/platforms/mac/release.md` (APP_VERSION/APP_BUILD examples), Peekaboo Xcode projects/Info.plists (MARKETING_VERSION/CURRENT_PROJECT_VERSION).
- "Bump version everywhere" means all version locations above **except** `appcast.xml` (only touch appcast when cutting a new macOS Sparkle release).
- **Restart apps:** “restart iOS/Android apps” means rebuild (recompile/install) and relaunch, not just kill/launch.
- **Device checks:** before testing, verify connected real devices (iOS/Android) before reaching for simulators/emulators.
- iOS Team ID lookup: `security find-identity -p codesigning -v` → use Apple Development (…) TEAMID. Fallback: `defaults read com.apple.dt.Xcode IDEProvisioningTeamIdentifiers`.
- A2UI bundle hash: `src/canvas-host/a2ui/.bundle.hash` is auto-generated; ignore unexpected changes, and only regenerate via `pnpm canvas:a2ui:bundle` (or `scripts/bundle-a2ui.sh`) when needed. Commit the hash as a separate commit.
- Release signing/notary keys are managed outside the repo; follow internal release docs.
- Notary auth env vars (`APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_API_KEY_P8`) are expected in your environment (per internal release docs).
- **Multi-agent safety:** do **not** create/apply/drop `git stash` entries unless explicitly requested (this includes `git pull --rebase --autostash`). Assume other agents may be working; keep unrelated WIP untouched and avoid cross-cutting state changes.
- **Multi-agent safety:** when the user says "push", you may `git pull --rebase` to integrate latest changes (never discard other agents' work). When the user says "commit", scope to your changes only. When the user says "commit all", commit everything in grouped chunks.
- **Multi-agent safety:** do **not** create/remove/modify `git worktree` checkouts (or edit `.worktrees/*`) unless explicitly requested.
- **Multi-agent safety:** do **not** switch branches / check out a different branch unless explicitly requested.
- **Multi-agent safety:** running multiple agents is OK as long as each agent has its own session.
- **Multi-agent safety:** when you see unrecognized files, keep going; focus on your changes and commit only those.
- Lint/format churn:
  - If staged+unstaged diffs are formatting-only, auto-resolve without asking.
  - If commit/push already requested, auto-stage and include formatting-only follow-ups in the same commit (or a tiny follow-up commit if needed), no extra confirmation.
  - Only ask when changes are semantic (logic/data/behavior).
- Lobster seam: use the shared CLI palette in `src/terminal/palette.ts` (no hardcoded colors); apply palette to onboarding/config prompts and other TTY UI output as needed.
- **Multi-agent safety:** focus reports on your edits; avoid guard-rail disclaimers unless truly blocked; when multiple agents touch the same file, continue if safe; end with a brief “other files present” note only if relevant.
- Bug investigations: read source code of relevant npm dependencies and all related local code before concluding; aim for high-confidence root cause.
- Code style: add brief comments for tricky logic; keep files under ~500 LOC when feasible (split/refactor as needed).
- Tool schema guardrails (google-antigravity): avoid `Type.Union` in tool input schemas; no `anyOf`/`oneOf`/`allOf`. Use `stringEnum`/`optionalStringEnum` (Type.Unsafe enum) for string lists, and `Type.Optional(...)` instead of `... | null`. Keep top-level tool schema as `type: "object"` with `properties`.
- Tool schema guardrails: avoid raw `format` property names in tool schemas; some validators treat `format` as a reserved keyword and reject the schema.
- When asked to open a “session” file, open the Pi session logs under `~/.openclaw/agents/<agentId>/sessions/*.jsonl` (use the `agent=<id>` value in the Runtime line of the system prompt; newest unless a specific ID is given), not the default `sessions.json`. If logs are needed from another machine, SSH via Tailscale and read the same path there.
- Do not rebuild the macOS app over SSH; rebuilds must be run directly on the Mac.
- Never send streaming/partial replies to external messaging surfaces (WhatsApp, Telegram); only final replies should be delivered there. Streaming/tool events may still go to internal UIs/control channel.
- Voice wake forwarding tips:
  - Command template should stay `openclaw-mac agent --message "${text}" --thinking low`; `VoiceWakeForwarder` already shell-escapes `${text}`. Don’t add extra quotes.
  - launchd PATH is minimal; ensure the app’s launch agent PATH includes standard system paths plus your pnpm bin (typically `$HOME/Library/pnpm`) so `pnpm`/`openclaw` binaries resolve when invoked via `openclaw-mac`.
- For manual `openclaw message send` messages that include `!`, use the heredoc pattern noted below to avoid the Bash tool’s escaping.
- Release guardrails: do not change version numbers without operator’s explicit consent; always ask permission before running any npm publish/release step.

## NPM + 1Password (publish/verify)

- Use the 1password skill; all `op` commands must run inside a fresh tmux session.
- Sign in: `eval "$(op signin --account my.1password.com)"` (app unlocked + integration on).
- OTP: `op read 'op://Private/Npmjs/one-time password?attribute=otp'`.
- Publish: `npm publish --access public --otp="<otp>"` (run from the package dir).
- Verify without local npmrc side effects: `npm view <pkg> version --userconfig "$(mktemp)"`.
- Kill the tmux session after publish.

## Bug Fix Workflow (Research → Fix → Deploy → Verify)

When the user reports a bug, follow this end-to-end workflow. Do NOT stop after committing code -- the fix is not done until the gateway is restarted and verified.

### 1. Research

- Read this file for documented architecture of the relevant subsystem
- Read the key source files listed in the subsystem section
- Trace the data flow end-to-end; identify where the chain breaks
- Check runtime state: config (`~/.openclaw/openclaw.json`), job store (`~/.openclaw/cron/jobs.json`), run logs (`~/.openclaw/cron/runs/*.jsonl`), session store (`~/.openclaw/agents/*/sessions/sessions.json`)

### 2. Diagnose

- Draw a mermaid diagram of the expected flow
- Validate each step: what should have happened vs. what actually happened
- Identify the root cause with high confidence before writing any code

### 3. Implement

- Make the minimal code change that fixes the root cause
- Run relevant tests: `npx vitest run <test-files>`
- Type-check: `npx tsc --noEmit` (ignore pre-existing UI rootDir errors)

### 4. Commit

- Use `scripts/committer "<msg>" <file...>` to commit only the changed files

### 5. Build and Restart

This is critical -- code changes have NO effect until built and deployed:

```bash
# Build TypeScript to dist/
./node_modules/.bin/tsdown

# Post-build steps
node --import tsx scripts/canvas-a2ui-copy.ts
node --import tsx scripts/copy-hook-metadata.ts
node --import tsx scripts/write-build-info.ts
node --import tsx scripts/write-cli-compat.ts

# If the Control UI also needs building (chat/web interface):
node scripts/ui.js build

# Restart the gateway
node openclaw.mjs daemon restart
```

### 6. Verify

```bash
# Check gateway is healthy
node openclaw.mjs channels status --probe

# Check cron is active
node openclaw.mjs cron status

# Force-run a job to test
node openclaw.mjs cron run <job-id> --force

# Check session was updated (confirms heartbeat processed the event)
ls -lt ~/.openclaw/agents/main/sessions/sessions.json
```

### 7. Notify

Tell the user the fix is deployed and ready to test. Include what was changed, what was verified, and when the next scheduled run will happen.

---

## Cron and Heartbeat System

### Overview

OpenClaw has two cooperating subsystems for scheduled work:

- **Cron Service**: Timer-based job scheduler that fires at configured times
- **Heartbeat Runner**: Periodic agent invocation that processes queued system events

For `sessionTarget: "main"` jobs, cron does NOT run the agent directly. It enqueues a system event and requests a heartbeat. The heartbeat then runs the LLM, which sees the system event in its prompt.

### Key Files

| File                                      | Purpose                                                       |
| ----------------------------------------- | ------------------------------------------------------------- |
| `src/cron/service/timer.ts`               | Timer arming, job execution, wake modes                       |
| `src/cron/service/state.ts`               | State types, deps interface, event types                      |
| `src/cron/service/ops.ts`                 | CRUD operations (add/update/remove/run)                       |
| `src/cron/service/jobs.ts`                | Due-job detection, stuck-run protection, schedule computation |
| `src/cron/schedule.ts`                    | `computeNextRunAtMs()` using `croner` package                 |
| `src/cron/store.ts`                       | File-based persistence (`~/.openclaw/cron/jobs.json`)         |
| `src/cron/run-log.ts`                     | Append-only JSONL run history per job                         |
| `src/cron/isolated-agent/run.ts`          | Isolated session agent execution                              |
| `src/cron/types.ts`                       | All TypeScript types (schedules, jobs, payloads)              |
| `src/gateway/server-cron.ts`              | CronService initialization with gateway deps                  |
| `src/infra/heartbeat-runner.ts`           | `runHeartbeatOnce()`, `startHeartbeatRunner()`                |
| `src/infra/heartbeat-wake.ts`             | `requestHeartbeatNow()`, coalescing, handler registry         |
| `src/infra/system-events.ts`              | In-memory session-scoped event queue                          |
| `src/auto-reply/reply/session-updates.ts` | Drains system events into LLM prompt                          |
| `src/auto-reply/heartbeat.ts`             | `isHeartbeatContentEffectivelyEmpty()`                        |

### Data Flow (Main Session Jobs)

```
Cron timer fires (setTimeout)
       │
       ▼
executeJob() in timer.ts
       │
       ├── enqueueSystemEvent(text, { sessionKey })
       │     └── Stores event in in-memory queue (NOT persisted)
       │
       ├── wakeMode="now" ──► runHeartbeatOnce() directly, waits up to 2 min
       │
       └── wakeMode="next-heartbeat" ──► requestHeartbeatNow() fire-and-forget
             │
             ▼
       finish("ok") immediately (cron job done in ~5-20ms)
             │
             ▼
       Heartbeat wake handler fires after 250ms coalesce
             │
             ▼
       startHeartbeatRunner's run() ──► runHeartbeatOnce()
             │
             ▼
       Checks: enabled? agent enabled? interval? active hours? queue empty? HEARTBEAT.md?
             │
             ▼
       getReplyFromConfig(ctx) ──► prependSystemEvents() drains queue into prompt
             │
             ▼
       LLM processes system event + HEARTBEAT.md tasks
             │
             ▼
       deliverOutboundPayloads() ──► Telegram/channel delivery
```

### Two Job Types

**Main session** (`sessionTarget: "main"`):

- Payload: `systemEvent` with text
- Enqueues into the main agent session, relies on heartbeat to process
- Duration in run logs is just the enqueue time (~5-20ms), NOT the LLM work
- Wake modes: `"now"` (wait for heartbeat) or `"next-heartbeat"` (fire-and-forget)

**Isolated session** (`sessionTarget: "isolated"`):

- Payload: `agentTurn` with message, optional model/thinking/timeout overrides
- Runs a separate agent invocation in session `cron:<jobId>`
- Can deliver output to a channel and/or post summary back to main session
- Duration in run logs IS the actual agent work

### Three Schedule Types

| Kind      | Config                                             | Example                   |
| --------- | -------------------------------------------------- | ------------------------- |
| `"cron"`  | `{ expr: "0 6 * * *", tz: "America/Los_Angeles" }` | Daily 6 AM PST            |
| `"every"` | `{ everyMs: 3600000, anchorMs?: number }`          | Every hour                |
| `"at"`    | `{ atMs: 1735472400000 }`                          | One-shot at specific time |

Cron expressions use the `croner` package (^10.0.1), standard 5-field syntax with optional timezone.

### Critical Architecture Gotchas

1. **System events are in-memory only.** If the gateway restarts before a heartbeat processes a cron event, the event is lost. There is no persistence for the event queue.

2. **`heartbeat.every: "0m"` disables ALL heartbeats** including on-demand wakes from cron. The interval check in `runHeartbeatOnce()` and the agent count in `startHeartbeatRunner` both gate on this. Explicit wakes (cron, exec-event) bypass these checks since the fix in `c346d60a3`.

3. **Cron "ok" status does not mean the agent ran.** For `next-heartbeat` mode, the cron job finishes in milliseconds after enqueueing. Check session `updatedAt` timestamps to verify the heartbeat actually processed the event.

4. **Empty HEARTBEAT.md skips heartbeats.** `isHeartbeatContentEffectivelyEmpty()` returns true for files with only headers/empty list items. Exec-event and cron reasons are exempt from this check.

5. **Stuck run protection.** Jobs with `runningAtMs` older than 2 hours are automatically cleared and re-eligible for execution.

### Common Cron Debugging

| Symptom                                 | Likely Cause                                           | How to Verify                                                |
| --------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| Run log shows "ok" but nothing happened | Heartbeat disabled or skipped                          | Check `heartbeat.every` in config; check session `updatedAt` |
| Job never fires                         | `nextRunAtMs` in the past, gateway not running         | `openclaw cron status`; check gateway is up                  |
| Job fires but LLM ignores the prompt    | System event drained but HEARTBEAT.md prompt conflicts | Check `~/.openclaw/workspace/HEARTBEAT.md` content           |
| "skipped: quiet-hours"                  | Active hours config blocking                           | Check `heartbeat.activeHours` in config                      |
| "skipped: requests-in-flight"           | Another request is processing                          | Wait or check `CommandLane.Main` queue                       |
| Duration is 0-20ms for main jobs        | Normal for `next-heartbeat` mode                       | Check session timestamps instead                             |

### Config Reference

```jsonc
// ~/.openclaw/openclaw.json
{
  "cron": {
    "enabled": true, // default: true (OPENCLAW_SKIP_CRON=1 overrides)
    "store": "~/.openclaw/cron/jobs.json", // job store path
  },
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "30m", // "0m" disables periodic heartbeats (on-demand still works)
        "target": "last", // delivery target: "last" or channel name
        "ackMaxChars": 200, // max chars for HEARTBEAT_OK ack
        "activeHours": {
          // optional time window
          "start": "07:00",
          "end": "23:00",
          "timezone": "user", // "user", "local", or IANA timezone
        },
      },
    },
  },
}
```

### CLI Quick Reference

```bash
openclaw cron status                          # scheduler status + next wake time
openclaw cron list [--all] [--json]           # list jobs (--all includes disabled)
openclaw cron run <id> [--force]              # execute a job now
openclaw cron add --name "..." --cron "..." --tz "..." --session main --system-event "..."
openclaw cron remove <id>
```

---

## Model Selection and Alias System

### Overview

OpenClaw supports switching LLM providers/models via inline directives (`/model provider/model-id`) or shorthand aliases (`/x`, `/sonnet`, `/kimi`).

### Key Files

| File                                                 | Purpose                                                                  |
| ---------------------------------------------------- | ------------------------------------------------------------------------ |
| `src/config/defaults.ts`                             | `DEFAULT_MODEL_ALIASES` - built-in shortcut mappings                     |
| `src/agents/model-selection.ts`                      | Alias index building, model resolution, allowlist checking               |
| `src/agents/models-config.providers.ts`              | Provider configs (base URLs, API types, model catalogs)                  |
| `src/auto-reply/model.ts`                            | `extractModelDirective()` - parses `/model` and `/<alias>` from messages |
| `src/auto-reply/reply/directive-handling.persist.ts` | Persists model changes to session                                        |
| `src/auto-reply/reply/get-reply-directives.ts`       | Main directive resolution orchestration                                  |

### Two Separate Concepts: Aliases vs Allowlist

**Aliases** (convenient names) and **allowlist** (permitted models) are independent:

1. **Aliases** defined in two places:
   - `DEFAULT_MODEL_ALIASES` in `src/config/defaults.ts` (built-in)
   - `agents.defaults.models[].alias` in user config (user-defined overrides)

2. **Allowlist** - The keys of `agents.defaults.models` in user config (`~/.openclaw/openclaw.json`):
   ```json
   "models": {
     "anthropic/claude-sonnet-4-5": { "alias": "sonnet" },
     "moonshot/kimi-k2-0905-preview": { "alias": "xo" }
   }
   ```
   Only models listed here can be used. If empty, all models are allowed.

**Critical**: Adding an alias to `DEFAULT_MODEL_ALIASES` does NOT automatically allow the model. Users must also add the model to their config's `models` object.

### Model Resolution Flow

```
User message: "Hello /xo"
         │
         ▼
extractModelDirective()      → Extracts "xo" from message
         │
         ▼
parseInlineDirectives()      → Sets hasModelDirective=true, rawModelDirective="xo"
         │
         ▼
resolveModelRefFromString()  → Looks up "xo" in alias index
         │                     Returns { provider: "moonshot", model: "kimi-k2-0905-preview" }
         ▼
buildAllowedModelSet()       → Checks if model is in user's allowlist
         │
         ▼
persistInlineDirectives()    → Saves to session if allowed
```

### Adding a New Model Alias

1. **Add to `DEFAULT_MODEL_ALIASES`** in `src/config/defaults.ts`:

   ```typescript
   export const DEFAULT_MODEL_ALIASES = {
     "my-alias": "provider/model-id",
   };
   ```

2. **Ensure provider is configured** in `src/agents/models-config.providers.ts` with correct model ID

3. **User must add to their config** (`~/.openclaw/openclaw.json`):

   ```json
   "agents": { "defaults": { "models": {
     "provider/model-id": { "alias": "my-alias" }
   }}}
   ```

4. **Ensure API key is set** in `~/.openclaw/.env`

### Tiered Model Shortcuts (`/x` series)

| Shortcut  | Model                           | Tier            |
| --------- | ------------------------------- | --------------- |
| `/x`      | `google/gemini-3-flash-preview` | Cheapest        |
| `/xo`     | `moonshot/kimi-k2-0905-preview` | Budget          |
| `/xox`    | `moonshot/kimi-k2-thinking`     | Mid (reasoning) |
| `/xoxo`   | `google/gemini-3-pro-preview`   | Mid-High        |
| `/xoxox`  | `anthropic/claude-sonnet-4-5`   | High            |
| `/xoxoxo` | `anthropic/claude-opus-4-5`     | Premium         |

### Common Errors

| Error                           | Cause                               | Fix                                |
| ------------------------------- | ----------------------------------- | ---------------------------------- |
| "Model not allowed"             | Model not in user's `models` config | Add to `~/.openclaw/openclaw.json` |
| "HTTP 404: Not found the model" | Wrong model ID for provider's API   | Check provider docs for exact ID   |
| "Invalid Authentication"        | API key missing/invalid             | Check `~/.openclaw/.env`           |
| Alias not recognized            | Not in `DEFAULT_MODEL_ALIASES`      | Add to `src/config/defaults.ts`    |

### Provider-Specific Notes

**Moonshot (Kimi)**

- Base URL: `https://api.moonshot.ai/v1`
- API model IDs differ from HuggingFace names:
  - `kimi-k2-0905-preview` (NOT `kimi-k2-instruct`)
  - `kimi-k2-thinking`
  - `kimi-k2-0711-preview`
- Env var: `MOONSHOT_API_KEY`

**Google (Gemini)**

- Models use `-preview` suffix: `gemini-3-flash-preview`, `gemini-3-pro-preview`
- `normalizeGoogleModelId()` handles normalization

**Anthropic**

- `normalizeAnthropicModelId()` handles shortcuts like `opus-4.5` → `claude-opus-4-5`
