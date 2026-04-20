# Recipe: headless scheduled run

You want the team to keep working after you close your laptop. This is the Stage 4 scenario the 4-Stages thesis called out. The Scaffold makes it a 5-minute setup.

## Prerequisites

- An accepted run with a manifest. You've run `/raos <objective>` interactively at least once. The `.agentic-os/runs/<run_id>/` folder exists.
- The run's manifest has `status` in `running`, `paused`, or `verifying`. A done or killed run won't advance.
- Claude Code CLI is on your PATH (check with `which claude`).

## Three transports, one entry point

All three scheduler templates call the same script: `<SKILL_DIR>/harness/bin/headless.sh <project_root> <run_id>`. Pick the transport that fits your box.

### macOS — launchd

1. Copy the template and fill the placeholders:
   ```bash
   cp <SKILL_DIR>/harness/schedule/launchd.plist.template \
      ~/Library/LaunchAgents/com.ragnar.raos.<OS_NAME>.<RUN_ID>.plist
   ```
   Then edit the copy and replace `<OS_NAME>`, `<PROJECT>`, `<RUN_ID>`, `<SKILL_DIR>`, `<INTERVAL>` (seconds, e.g., `3600` for hourly).
2. Load it:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.ragnar.raos.<OS_NAME>.<RUN_ID>.plist
   launchctl start com.ragnar.raos.<OS_NAME>.<RUN_ID>
   ```
3. Logs land at `<PROJECT>/.agentic-os/runs/<RUN_ID>/launchd.stdout.log` and `launchd.stderr.log`, plus the run's own `headless.log`.
4. Remove:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.ragnar.raos.<OS_NAME>.<RUN_ID>.plist
   rm ~/Library/LaunchAgents/com.ragnar.raos.<OS_NAME>.<RUN_ID>.plist
   ```

### Windows — Task Scheduler

1. Copy the template to a working file:
   ```powershell
   Copy-Item <SKILL_DIR>\harness\schedule\taskscheduler.xml.template raos-task.xml
   ```
2. Edit the copy. Replace `<OS_NAME>`, `<PROJECT>` (use Windows-style paths), `<RUN_ID>`, `<SKILL_DIR>`, `<USER>` (your Windows username), `<INTERVAL>` (ISO 8601 duration, e.g., `PT1H` for hourly, `PT30M` for every 30 minutes).
3. Import:
   ```powershell
   schtasks /Create /TN "RAOS-<OS_NAME>-<RUN_ID>" /XML raos-task.xml
   ```
4. Run once manually to verify: `schtasks /Run /TN "RAOS-<OS_NAME>-<RUN_ID>"`
5. Note: `headless.sh` is bash. The template invokes it through Git Bash. If you run Claude Code under WSL, change the `<Command>` line to `wsl.exe` and the arguments accordingly.
6. Remove: `schtasks /Delete /TN "RAOS-<OS_NAME>-<RUN_ID>" /F`

### Cross-platform — GitHub Actions

Easier if your project is already a GitHub repo and you want runs to happen whether or not your machine is on.

1. Copy `<SKILL_DIR>/harness/schedule/github-actions.yaml.template` to `.github/workflows/raos-<OS_NAME>-<RUN_ID>.yml` in your repo.
2. Replace `<OS_NAME>`, `<RUN_ID>`, `<CRON>` (e.g., `"0 */2 * * *"` for every 2 hours).
3. Add a repo secret `ANTHROPIC_API_KEY`. Settings → Secrets and variables → Actions.
4. Commit and push. First scheduled run will appear in the Actions tab.
5. The workflow will commit any code changes back to the branch. Comment out the final step if you want manual review instead.

## What happens on each wake

- `headless.sh` is invoked with `<project_root> <run_id>`.
- It sets the run as active (`.agentic-os/runs/.active` → `<run_id>`).
- It calls `claude -p "/raos resume <run_id>"`.
- The team-lead reads the manifest, current phase, last checkpoint, and recent trace. It continues from where it left off.
- All hooks fire as normal. Trace appends. Costs roll up. Gates record.
- If the run hits a guidance-bucket gate, team-lead writes the approval request to `manifest.gates[]` with `decision: deferred` and stops. The next scheduled wake-up will see the deferred gate and stop again until a human resumes via the interactive session and answers it.
- If the run completes (`status: done`), subsequent wake-ups log "run already done, nothing to do" and exit clean. You can leave the scheduler on; it won't redo work.

## Kill the scheduled run

Same kill switch as interactive:

```bash
/raos kill <run_id>
# or manually:
echo "stop" > <project>/.agentic-os/runs/<run_id>/KILL
```

The next scheduled wake-up will see the sentinel in `pre-tool-use.sh` and exit 2 immediately. Headless log records it. Removing the sentinel and the scheduler entry restores or ends the cycle.

## Safety rails

- Set `budgets.enforce: true` in the manifest for scheduled runs. Observability-only is fine interactively; headless should have a hard stop.
- Leave approval gates intact. Scheduled runs should not auto-approve destructive actions. If a run keeps deferring, that's the signal — a human is needed.
- Check the run's `headless.log` once a day. If the team is making no progress across 5 wake-ups, surface to yourself and decide whether to re-scope.
