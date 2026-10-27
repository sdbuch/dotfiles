---
name: tmux-safe-recovery
description: Safely inspect, inventory, save, restore, reattach, and reconstruct tmux-resurrect/tmux-continuum workspaces under WezTerm without allowing an agent sandbox or agent-specific environment to contaminate the tmux server. Use for missing or crashed WezTerm tabs, power-loss recovery, continuum/resurrect restores, identifying prior pane or Codex work, readonly-database or `nice` permission errors limited to restored panes, terminal-color loss after restore, attaching restored tmux sessions as separate WezTerm tabs, finding saved recovery manifests, and relaunching recorded Codex threads.
---

# Safe tmux Recovery

Treat the tmux server as a long-lived security boundary. Every pane process is
forked by the server and inherits its macOS sandbox and environment. A clean
GUI process parent and a sanitized spawn environment are separate requirements:
`wezterm cli spawn` can ask the GUI to create the process while still supplying
environment values from the calling agent.

## Pin the allocator-safe tmux binary

On this workstation, every replacement server and restored client must use the
verified recovery binary. Resolve it before any server mutation:

```sh
~/.codex/skills/tmux-safe-recovery/scripts/resolve-tmux-binary
```

The resolver defaults to
`~/.local/opt/tmux-3.7c-jemalloc/bin/tmux` and fails closed unless
the binary is tmux 3.7c or newer and is linked with jemalloc on macOS. Use
`--check ABSOLUTE_PATH` to validate a different future binary. Do not create or
replace a server with `/opt/homebrew/bin/tmux` merely because it is first on
`PATH`; the September 2026 recovery regression selected Homebrew tmux 3.7b,
removed the jemalloc workaround, and reproduced the copy-mode scroll crash.

Use the resolver's `--exec` mode in GUI spawn commands so validation and
execution cannot diverge. Client-only inspection of an already-running server
may use `tmux`, but confirm the actual server executable from its PID rather
than inferring it from the client command.

## Preserve evidence first

Start read-only. Do not kill sessions, rewrite `last`, restore, or create a
server merely to diagnose.

1. Inspect existing sessions and the server PID:

   ```sh
   tmux list-sessions -F '#{session_name}\tserver=#{pid}\tsocket=#{socket_path}\tattached=#{session_attached}'
   ps -p SERVER_PID -o pid=,ppid=,lstart=,command=
   ```

   Map every client before running restore or attach commands:

   ```sh
   tmux list-clients -F '#{client_tty}\t#{client_pid}\t#{client_session}\t#{client_last_session}'
   tmux list-panes -a -F '#{pane_tty}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_pid}'
   /Applications/WezTerm.app/Contents/MacOS/wezterm cli list --format json
   ```

   A direct client's `client_tty` matches a WezTerm `tty_name`. A nested
   client's `client_tty` instead matches a tmux `pane_tty`. Resolve the pane
   containing an agent from `TMUX_PANE`; do not infer it from attachment state,
   tab ordering, or the PID suffix in a session name:

   ```sh
   tmux display-message -p -t "$TMUX_PANE" \
     '#{session_name}:#{window_index}.#{pane_index}\t#{pane_tty}'
   ```

2. Check only agent, sandbox, and display-control keys plus known Codex PATH
   markers; do not dump the full environment because it can contain
   credentials:

   ```sh
   tmux show-environment -g | \
     rg '^(CODEX|SANDBOX|NO_COLOR=|FORCE_COLOR=|CLICOLOR_FORCE=)'
   tmux show-environment -g PATH | \
     rg '(@openai/codex|/\.codex/tmp/|codex\.system)'
   ```

   Both commands should print nothing for a clean server.

3. Inspect snapshot integrity and inventory before restoring:

   ```sh
   ls -l ~/.local/share/tmux/resurrect/last
   test -e ~/.local/share/tmux/resurrect/last
   sed -n '1,160p' ~/.local/share/tmux/resurrect/last
   ```

   A symlink can exist while its target is missing. Treat a failed `test -e`
   as an invalid snapshot.

4. Read `pane` records for session, cwd, foreground command, and full command.
   If `agent_context` records exist, list them with:

   ```sh
   ~/dotfiles/scripts/tmux-agent-context list ~/.local/share/tmux/resurrect/last
   ```

   Also inspect `pane_contents.tar.gz` when visible-pane capture is enabled.

## Diagnose sandbox contamination

Consider the server contaminated when its global environment contains
`CODEX_SANDBOX`, `CODEX_PERMISSION_PROFILE`, a Codex thread ID, or Codex's
temporary/bootstrap PATH entries. Treat `NO_COLOR` as environment poisoning
rather than a sandbox marker. Typical pane-only symptoms include:

- `nice(...) failed: operation not permitted` during shell startup
- writable user-owned files appearing readonly, especially Codex's SQLite DB
- normal commands working in a plain WezTerm window but failing in tmux tabs
- restored terminal applications unexpectedly rendering in monochrome

Filesystem ownership changes and deleting the SQLite DB do not fix this. A
live server cannot shed an inherited kernel sandbox; replace it.

Changing the server's global environment affects only future children; shells
and applications already forked by the server retain their original values. If
environment contamination is caught after restore but before work resumes,
replace the server again rather than repairing every pane individually.

## Do not restore through a live agent client

Do not run tmux-resurrect's `restore.sh` from an agent tool process in a live
multi-client server. The upstream script uses unscoped `tmux switch-client`
while restoring active panes, windows, and session state. It can retarget the
WezTerm client displaying an unrelated agent, making that agent appear lost
even though its pane process is still alive.

Prefer a full continuum restore only when starting a clean replacement server.
If a live server needs an incremental restore, first record the complete client
map. Run the restore from a dedicated disposable tmux client spawned by the
WezTerm GUI, so any unscoped switch affects only that client. Verify that every
pre-existing `client_tty` still targets its original session afterward.

Never guess which client to "switch back." Use `tmux switch-client -c TTY`
only after matching that exact TTY to the intended WezTerm tab and only when
the user wants to repurpose that tab. Prefer opening a new attached tab.

## Save safely before replacement

Stopping a server closes every attached tmux-backed terminal. Do not do so for
a diagnosis-only request. When replacement is authorized, run the following
from a healthy non-tmux shell:

```sh
tmux set-option -g @continuum-save-interval 0
sleep 2
~/.tmux/plugins/tmux-resurrect/scripts/save.sh
test -e ~/.local/share/tmux/resurrect/last
```

Disabling autosave temporarily avoids same-second save races that can leave a
broken `last` symlink. Verify the target and inspect its pane count before
killing the server.

## Write a recovery manifest

When the user asks to prepare for a restart, write a dated human-readable
manifest at `~/notes/tmux-restart-recovery-YYYY-MM-DD.md` after validating the
snapshot. Include:

- the resolved `last` snapshot target and integrity result;
- every saved session, title, cwd, foreground command, and agent kind;
- each exact `codex resume THREAD_ID` command and transcript path when known;
- pane counts, visible-content archive paths, and any metadata uncertainty;
- recently closed threads separately from sessions that will be restored.

After verifying the dated manifest, copy it to
`~/notes/tmux-restart-recovery-latest.md` as a predictable lookup path. Keep the
dated file as the durable record. Treat embedded `agent_context` records as the
machine-readable source of truth and the Markdown manifest as a readable
fallback; never fabricate a thread ID to make the manifest complete.

## Start the replacement outside the sandbox

Never run `tmux new-session`, `tmux start-server`, or the first server-creating
tmux command through an ordinary agent tool execution. Unsetting `CODEX_*`
variables is insufficient because the kernel sandbox is inherited separately.

Use one of these paths:

- Ask the user to press their WezTerm Cmd+T binding from a healthy window.
- With approval, ask the running WezTerm GUI to spawn the tmux command via
  `wezterm cli spawn`; the GUI, not the agent, then becomes the process parent.
- Use an explicitly unsandboxed host execution only when its clean process
  boundary is certain.

When spawning through `wezterm cli` from an agent, run the requested tmux
command through the bundled sanitizer. It removes `TMUX`, agent/sandbox keys,
color overrides, and Codex vendor/bootstrap/temp PATH entries without printing
environment values:

```sh
/Applications/WezTerm.app/Contents/MacOS/wezterm cli spawn \
  --window-id WINDOW_ID -- \
  ~/.codex/skills/tmux-safe-recovery/scripts/clean-tmux-env \
  ~/.codex/skills/tmux-safe-recovery/scripts/resolve-tmux-binary \
  --exec new-session -s tmux-recovery-startup-clean
```

After the clean server starts, let continuum restore the validated snapshot.
Before resuming agents, verify the new server's executable, PID/start time,
sanitized keys and PATH, and client terminal capabilities:

```sh
tmux show-environment -g | \
  rg '^(CODEX|SANDBOX|NO_COLOR=|FORCE_COLOR=|CLICOLOR_FORCE=)'
tmux show-environment -g PATH | \
  rg '(@openai/codex|/\.codex/tmp/|codex\.system)'
tmux list-clients -F \
  '#{client_tty}\t#{client_termname}\t#{client_termfeatures}\t#{client_session}'
```

The first two commands must print nothing. Resolve the server PID, verify `ps`
shows the resolver's absolute executable, and on macOS verify the live process
has jemalloc loaded:

```sh
ps -p SERVER_PID -o pid=,ppid=,lstart=,command=
lsof -p SERVER_PID | rg 'tmux-3\.7c-jemalloc|libjemalloc'
```

Do not equate a GUI parent with a clean environment merely because the server
has PPID 1 after daemonizing. Do not resume agents if the executable or loaded
allocator check fails; replace the server with the validated snapshot again.

## Reattach one session per WezTerm tab

List restored sessions and the existing client map first. For an agent-driven
attachment, always have the WezTerm GUI spawn a direct client:

```sh
/Applications/WezTerm.app/Contents/MacOS/wezterm cli spawn \
  --window-id WINDOW_ID -- \
  ~/.codex/skills/tmux-safe-recovery/scripts/clean-tmux-env \
  ~/.codex/skills/tmux-safe-recovery/scripts/resolve-tmux-binary \
  --exec attach-session -t SESSION
```

Do not run `env -u TMUX tmux attach-session` directly through an agent's shell
tool. Opening another GUI tab does not move the already-running agent or its
tool execution context into that tab. Unsetting `TMUX` only disables tmux's
nesting guard; stdin and stdout still belong to the original pane, so the new
client can become nested there and hide the agent behind it.

A user may type the attach command in a genuinely non-tmux tab after verifying
that `printenv TMUX` prints nothing. `attach-session` does not move or delete a
WezTerm tab. If it appears to, stop and remap WezTerm TTYs, tmux client TTYs,
and pane TTYs before changing anything.

## Reconstruct the restored workspace

When the user asks to split or rebuild a restored workspace, complete the full
reattachment workflow instead of stopping after listing commands:

1. Compare live session names with the `pane` records in the validated
   snapshot. Recreate only saved sessions; exclude an empty startup session
   created after restore.
2. Build a session-to-title/cwd/thread map in this order:
   - restored pane options such as `@agent_title`, `@agent_cwd`, and
     `@agent_thread_id`;
   - `agent_context` records from the validated snapshot;
   - `~/notes/tmux-restart-recovery-latest.md`, but only when its snapshot name
     or complete session inventory matches the restored workspace;
   - a dated `~/notes/tmux-restart-recovery-*.md` containing the snapshot
     basename;
   - standard `pane` records, rollout files, or the local Codex database for
     missing legacy metadata.
3. Report uncertainty and stop for ambiguous mappings. Never match sessions by
   tab order, PID suffix, or similar titles.
4. Reuse an existing direct client for an already attached saved session. Ask
   the WezTerm GUI to spawn one direct client for every other saved session,
   recording an explicit session-to-returned-pane-ID map. If spawning in
   parallel, retain result identity; never infer the map from completion order.
5. Restore the saved human-readable label with the tab-title helper, for
   example:

   ```sh
   WEZTERM_PANE=SPAWNED_PANE_ID \
     ~/dotfiles/scripts/agent-tab-title --literal "SAVED_TITLE"
   ```

6. Verify that every saved session has exactly one direct client whose
   `client_tty` matches a WezTerm `tty_name`, and that no client TTY matches a
   tmux pane TTY.
7. Continuum may switch the disposable startup client to a restored session.
   Reuse that exact client. Remove the startup session only after verifying it
   is detached, contains one idle shell pane, and is absent from the snapshot.

If a restored session disappears while recovery is in progress, remap clients,
panes, and processes, then ask whether the user closed it intentionally before
recreating it. Concurrent user action is not recovery loss. Once confirmed,
exclude intentionally closed sessions from the next snapshot.

If the request only asks to reattach or split tabs, stop before launching
agents. If it explicitly asks to resume, relaunch, or start the recorded Codex
sessions, continue with the sequential workflow below without asking again.

## Recover agent work

Do not add `codex` to `@resurrect-processes`: resurrect cannot reliably retain
the selected Codex thread and may launch duplicates or an interactive resume
picker. Restore shells/layouts, then use the saved metadata:

```sh
codex resume THREAD_ID
```

When no `agent_context` record exists, correlate standard snapshot fields with
Codex's local thread database or rollout files. State uncertainty explicitly;
`codex resume` without an ID does not reveal which thread was selected.

List resume commands before starting them. Do not launch multiple Codex TUIs
with `send-keys` unless the user explicitly asks to resume those threads.

When bulk resume is explicitly authorized, launch and verify one session at a
time:

1. Confirm that the exact target pane is alive, is mapped to the intended
   session, and is at a shell:

   ```sh
   tmux display-message -p -t SESSION:WINDOW.PANE '#{pane_current_command}'
   ```

   `list-panes -t` still lists every pane in the target window. Do not type
   over Neovim or another foreground process.
2. Send the exact recorded `cd CWD && codex resume THREAD_ID` command.
3. Poll the pane command and process arguments until the exact thread ID is
   running before starting the next session. Treat a return to the shell as a
   failed resume even when `send-keys` succeeded.
4. If Codex updates itself and says to restart, let that installation finish,
   then resend the same resume command. Do not start other Codex clients while
   an updater or state-database migration is active.
5. If concurrent startup reports a duplicate-column or migration error, keep
   already-running clients intact, wait for the active migration to settle,
   and retry only the failed session sequentially. Never delete, move, or
   replace the Codex database as a recovery shortcut. Run `codex doctor` and
   stop for user direction if the error persists.
6. Verify every requested thread ID from live process arguments, confirm the
   editor panes remain unchanged, and report any deliberately detached startup
   session.

When restarting a running Codex TUI to repair its environment, capture its tail
first. One Ctrl-C may interrupt an active turn without exiting the TUI. Poll the
exact pane command after each Ctrl-C, never send a shell command until it is
actually back at the shell, and send a second Ctrl-C only when interrupting and
restarting that session is authorized. Resume with the required correction in
the shell, for example:

```sh
unset NO_COLOR; cd CWD && codex resume THREAD_ID
```

Verify the restarted native process does not contain the bad key by filtering
only the relevant environment tokens; never print its full environment:

```sh
ps eww -p CODEX_PID | tr ' ' '\n' | \
  rg '^(NO_COLOR|FORCE_COLOR|CLICOLOR_FORCE|TERM|COLORTERM)='
```

## Diagnose monochrome restored applications

Separate terminal capability from application policy. First inspect the exact
client:

```sh
tmux info -t CLIENT_TTY | rg 'colors:|RGB:|setaf:|setrgbf:'
```

If tmux reports 256 colors/RGB but the application is monochrome, inspect only
`NO_COLOR`, `FORCE_COLOR`, `CLICOLOR_FORCE`, `TERM`, and `COLORTERM`. A running
process cannot shed inherited environment values; restart it only after saving
its exact thread/session identity.

## Finalize the recovered state

After attachments, application resumes, and intentional closures settle, take
a new explicit snapshot using the same autosave-race precautions as the
pre-replacement save. Validate it against the live session/pane/thread
inventory, restore the configured continuum interval, preserve a dated pane
archive, and update the recovery manifest. This prevents a deliberately closed
session or obsolete startup session from returning on the next restore and
persists upgraded legacy metadata.

## Configure future snapshots

Prefer both structured metadata and a small visual fallback:

```tmux
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-pane-contents-area 'visible'
set -g @resurrect-hook-post-save-layout '~/dotfiles/scripts/tmux-agent-context append-snapshot'
set -g @resurrect-hook-post-restore-all '~/dotfiles/scripts/tmux-agent-context restore'
```

The tab-title helper should record the concise title, raw request summary, cwd,
agent kind, and exact Codex thread ID as pane options. Visible capture is a
fallback for editors, shells, and agent TUIs; remember that it stores terminal
contents locally and may therefore contain sensitive text.
