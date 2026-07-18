# safety-rules.md — the do-not-touch list

These override convenience, speed, and "it's probably fine" every single time.
When a rule here conflicts with a cleanup action, the rule wins and the action
becomes a *flagged item the user decides*, not something you do.

## 1. Pinned simulators are sacred *(iOS/macOS only)*

Projects often declare a canonical/pinned test simulator by name + UDID in their
docs. They exist on purpose, take several GB of runtime each, and are expensive
to recreate. **Never propose deleting one.** Before touching any sim:

```bash
grep -rinE "pinned|UDID|simulator" <projects-root> --include="*.md" \
  | grep -iE "pin|udid|canonical"
```

Exclude every UDID/name that appears. The only legitimate sim cleanup targets
are: (a) a non-pinned sim *you* booted this session (shutdown), and (b) leaked
ephemeral clones in `~/Library/Developer/XCTestDevices` under `--deep`
(`xcrun simctl --set testing delete all`). Those clones are never pinned.

## 2. Never merge or push to main

The feature-branch flow is: work on a branch, merge only after green + docs, and
the *user* does the merge. wrap-up commits and pushes the feature branch; it does
not land it on main. If your harness has a merge-to-main guard hook, bypassing it
is the **user's** decision, never wrap-up's.

**If the session worked directly on `main`/`master`**, do NOT auto-commit-and-push
— a guard will deny the push (leaving the commit stuck locally with no clean
resolution), and without a guard you'd be pushing to main unasked. Detect it
(`git branch --show-current` ∈ {main, master}) and surface as a ⚠️ decision:
"You're on `main` in <repo> — I won't auto-push. Move these changes to a feature
branch, or authorize the push yourself." That's the honest reading of this rule:
wrap-up pushes the *feature branch*; no feature branch means it's a finished-work
question, not a cleanup one.

## 3. Never destroy uncommitted work

A worktree or working tree with uncommitted changes is **data at risk**. Default
to *preserving* it (commit on its branch, or leave it dirty and flag it). Never
`git reset --hard`, `git checkout -- .`, `git clean -fd`, or `git worktree
remove --force` over uncommitted changes without explicit, specific
confirmation. `git status` + `git stash -u` before any working-tree-overwriting
command.

A worktree is removable only when ALL hold: clean tree, no unpushed commits,
branch merged (verified against the remote — squash-merges can hide this). A
branch with **no upstream** counts ALL its commits as unpushed — never read an
errored/empty `git log @{u}..` as "nothing to lose" (that's a silent data-loss
path). **Re-verify this full invariant in Phase 3 immediately before each
removal**, not from the Phase-1 scan result: minutes and several mutations pass
between check and delete, and the loss is irreversible (time-of-check/time-of-use).

## 4. Never commit secrets

No `.env`, no API keys, no tokens, no `DATABASE_URL` in a commit or a command.
A secret-manager's *config* file is usually safe to commit; the `.env` it
replaces never is. If staging changes, scan the diff for secret-shaped strings
before committing.

## 5. Session scope is the default; --deep is gated per item

Without `--deep`, only touch what *this* session created: your servers, your
scratchpad, sims you booted, worktrees you made. `--deep` widens the net to
machine-wide orphans, but every deletion in that tier is still presented
individually and approved individually — `--deep` is "look wider", not "delete
freely".

## 6. The scan is read-only

Phase 1 (SCAN) and `--dry-run` mutate nothing — no kills, no deletes, no
commits, no tracker writes. Every change happens in Phase 3 after a single
explicit approval. `--yes` collapses the approval for the auto-safe tier only;
it never auto-runs a destructive (⚠️) item.

## 7. Don't kill what you didn't start (without --deep + confirmation)

A long-running dev server from a *prior* session may be something the user is
actively relying on in another terminal. Session scope only stops servers you
started. `--deep` may propose stopping older ones, but name them (PID, command,
start time) and confirm — don't assume idle means abandoned.

**Kill by attributed PID only — NEVER by project-path pattern.** Stop a server by
the exact PIDs you identified (the tree root + its known children). Do NOT
`pkill -f <project-path>` or grep-the-path-and-kill-all to "catch survivors" —
build tools (`tsc --noEmit`), git hooks (a `pre-push` script), and **concurrent
agent sessions** all reference the same project path and get caught in the net.

This is not hypothetical: a `--deep` run once `kill -9`'d a peer session's live
`git push` (its pre-push hook) because the cleanup matched the project path
broadly. If a PID survives killing the tree root, re-identify *that PID* and
re-attribute it by T0 + cwd — a process **newer than the orphan**, or tied to a
shell snapshot other than this session's, is someone else's live work; exclude
it. If you run parallel sessions at all, assume peers exist and that "matches the
path" ≠ "is the orphan."

## 8. "Safe to exit" is a promise, not a formality

Only print the unqualified ✅ close-out when the scan genuinely comes back clean.
If a real code-review finding is open, a worktree is dirty by choice, or a server
was left running on purpose, the verdict must say so. A false "all clean" is
worse than no wrap-up at all — it's the one thing that breaks the trust this
skill exists to create.

Two mechanical rules enforce this, not just good intentions:

- **Re-verify, don't assert.** Every line in the close-out must come from a probe
  re-run *after* Phase 3 cleanup — not from the Phase-1 scan and not from "I ran
  the command, so it worked." Servers: confirm the **port** is free, not that a
  PID vanished. Push: capture `git push` exit 0, then `git fetch && git log @{u}..`
  empty. Tracker: re-fetch the issue. Worktrees/sims: re-list and confirm absent.
- **UNKNOWN forbids the unqualified ✅.** A probe that errored (sandbox/XPC,
  missing key, network) is UNKNOWN, never CLEAN. Any UNKNOWN category downgrades
  the verdict to "⚠️ Safe to exit *except*: <category> couldn't be checked —
  verify manually." Never let a failed probe's empty output read as "0 / clean."
