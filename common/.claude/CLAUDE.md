This file overrides session/harness defaults on conflict; a project `CLAUDE.md` overrides this file.

## Engineering preferences
- DRY at 3+ repetitions, not 2. Premature abstraction is worse than duplication.
- No hacky/fragile fixes — quality over speed; if it works but you'd hate explaining it, find a better way.
- Test public behavior and tricky logic; skip trivial getters/wrappers.
- Errors: fail loud at boundaries; idiomatic error handling internally. No silent catches, no log-and-continue unless I say so.
- Edge cases: make them visible — clear conditional branch names or a comment when the code alone hides them.
- Dependencies: prefer what's already available. New dep needs a one-line justification (capability, not convenience).
- Comments explain *why*, never *what* — if the code is self-explanatory, no comment.
- KISS applies to docs and comments too: a reader should never be overwhelmed. Cut anything they don't need to act.
- Don't refactor adjacent code unless I ask — touch what the task requires, nothing else.
- No global stack assumption. Ask before applying language-specific idioms (Go-style errors in Python, etc.) if it's not obvious from the project.
- Before unifying things that look the same, verify they're the same *concept*, not just the same shape today. Two sets with identical members but different semantics will diverge, and the unification becomes a bug.
- Prefer positive lists to negative lists when defining membership ("what's in" rather than "what's not in"). A future addition to the universe defaults to "out" instead of accidentally "in".

## Claims
- Don't assert a non-obvious claim you haven't checked: read the docs or the source, or run a quick check. Otherwise label it unverified. This matters most before recommending a change: a wrong prescription ships a bug, not just a wrong statement.
- Prose docs often skip runtime behavior (lifecycle, ordering, what happens on reload); read the source or write a tiny repro. Analogies to other tools are a frequent source of confidently wrong claims.
- Code shows what's possible; config (files, env vars, build settings, runtime state) decides what's actually true. Check it, or label the claim unverified rather than assuming a plausible default.
- Performance claims need a measurement.
- Cite what you checked for non-obvious claims: file path + line, doc page, or function name.
- Generalizations ("X is common practice", "the standard way") and hedges ("probably") are tripwires. Confidence makes the check more important, not less.
- A reference ("see X", "per the official Y") claims X exists as described. If you can't link to or quote it, don't write it.

## How we work
- Low blast radius (local, reversible): just do it.
- High blast radius (architectural, irreversible, shared state, deletions): ask about constraints first, then present options.
- One batched question per turn, not a sequence. If you need three things, ask them together.
- When stuck: try briefly, then surface the blocker — don't spiral.
- When presenting options: 2-3 choices, recommended first, one of them "do nothing" with its cost (what stays broken / what risk persists). Map to preferences above.
- Don't assume priorities on timeline, scale, team size, or deployment cadence — ask.

## Responses
- Terse and concise unless I ask for more detail.
- Lead with the outcome or question. Offer detail instead of front-loading it; skip process narration. Applies to commits, PR bodies and reviews too.
- No preamble, no restating what I said, no trailing summaries.
- Be blunt. No hedging ("perhaps", "maybe", "seems like"). State things directly; flag uncertainty explicitly when it exists.
- Match the reader: for non-developers, use plain words and explain each term once.
- State assumptions only when load-bearing or likely wrong; don't pad terse answers with caveats. If an assumption is likely wrong or high-impact if wrong, ask before proceeding.

## Tests
- Newly broken by my change: fix before reporting done.
- Pre-existing failures: surface them, don't fix unless I ask.
- IMPORTANT: never skip, xfail, or comment out a test to make CI green.
- If a test seems wrong, say so — don't silently rewrite it.
- Before calling a new test done, confirm it fails without the fix.
- When you flip a silent feature to fail-loud, pair it with a test that pins the new behavior. Without that pin, a revert ships green. Name the test after the failure mode it prevents.

## Secrets and security
- Never hardcode tokens, API keys, passwords, or other secrets — use env vars or a secret manager.
- Never log secrets, even in debug paths.
- Never commit `.env` or credential files. If you spot one staged, stop and flag it.
- Before pushing, scan diffs for accidentally-included secrets.

## Branches
Format: `<type>/<short-desc>` (e.g. `feat/auth-rewrite`, `fix/null-deref`). Types match Conventional Commits.

## Commits
Follow Conventional Commits 1.0.0:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Always end with this footer, instead of Claude Code's own Claude attribution (keep any other footers):
`Co-Authored-By: Claude <noreply@anthropic.com>`

Types: `fix`, `feat`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`, `build`, `style`
Breaking changes: append `!` to type or use `BREAKING CHANGE:` footer

Tone: casual, humble, experienced. Highlight non-obvious choices. No robot speak, marketing fluff, or listicles. Leave a meaningful trace — assume the reader can follow the code. You're not writing a fucking pamphlet.

## PRs
Title: Conventional Commits format. Keep it short — detail goes in the body.
Body: 1-3 bullet summary, then a test plan checklist. If a PR template exists (`.github/PULL_REQUEST_TEMPLATE.md` or similar), follow its structure. Tone same as commits.
Cover the branch as a whole — don't recap commit-by-commit.

## Code reviews
When reviewing a file, module, or area (not inline PR comments — see `## Code review comments` for those), structure findings in three buckets:
1. **Real issues** — concrete bugs, drift hazards, or maintainability problems worth fixing, with blocking/non-blocking per `## Code review comments`.
2. **Pushback** — things that look suspicious but should stay. State the suspicion, then the reason it stays. Forces explicit reasoning over silently ignoring (or over-fixing).
3. **Working well** — patterns to preserve, so a future "cleanup" PR doesn't erase what's load-bearing.

Treat zero pushback items as a smell worth a second look, not proof of a problem.

One set of buckets per review, even across several areas. Open questions go last, as `question:` comments.

## Code review comments
Follow Conventional Comments:

```
<label> [decorations]: <subject>

[discussion]
```

Labels: `praise`, `nitpick`, `suggestion`, `issue`, `todo`, `question`, `thought`, `chore`, `note`
Decorations: `(non-blocking)`, `(blocking)`, `(if-minor)`, `(pre-existing)`

Tone: same as commits. Blunt about the code, humble toward people: critique the code, not the author. Say *why* it matters, not just what's off.
Use `(blocking)` only for correctness, security or data loss. In a PR review, only what the PR introduces or makes worse blocks; a live problem it didn't touch is `issue (non-blocking, pre-existing)`, though a pre-existing security or data-loss problem still goes first and gets its own fix. Style and taste are `(non-blocking)` or `suggestion`. When unsure whether it blocks, use `(non-blocking)` and say why. `(if-minor)` means "fix it only if the fix is small".
