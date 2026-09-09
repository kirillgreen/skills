# Artefact naming grammar — the worked example

**This is an example convention, not the product.** It exists so the machinery has something
concrete to enforce and so `tests/run.sh` has something to assert against. Replace it with
your own: change the formula, the vocabularies, the folders — then change `naming.conf` to
match, and keep the two in step (`tests/run.sh` fails if the genre table here and the `genre`
rows there disagree, in either direction).

What is *not* negotiable is the shape of the thing: a filename is a small record with named
slots, a closed vocabulary for the slots that have one, and exactly one separator per job.
A convention without those three properties cannot be validated by anything, human or hook.

## Formula

    ⟨key⟩ ⟨Scope⟩ · ⟨Type⟩ — ⟨title⟩ (⟨qualifier⟩).ext

| Slot | Rule |
|---|---|
| key | ISO date `YYYY-MM-DD` of the **event** (transcripts, meetings) else of creation; `ADR-NNNN` for a numbered series; none for evergreen notes |
| Scope | project or area code from the closed list — **only in cross-project folders**. Inside a project's own tree: omit. An issue key (`ENG-233`) may replace it |
| Type | genre from the closed list — **only when it differs from the folder's default genre** (table below) |
| ` — ` | the one em-dash, between the head (key · scope · type) and the title. No head → no dash |
| title | 3–8 words, sentence case; lowercase after the dash unless a proper noun; the language of the folder's audience; no trailing period |
| (qualifier) | one trailing parenthetical: `(v2)` `(draft)` `(round 2)` `(RU)` `(2019)` |

## Separators — each sign does one job

- Space after the key · ` · ` between Scope and Type · ` — ` head|title, exactly one · `–`
  ranges only, no spaces (`27.07–06.08`, `W1–W3`) · `-` only inside compound words
  (`text-to-graph`, `ENG-233`) · `( )` qualifier at the end.
- **Never:** `{ }` (shell brace expansion, and they collide with template placeholders) ·
  `_` in prose names (reserved for ALLCAPS constants) · kebab titles
  (`2026-09-05-quarterly-review`) · spaced en-dash ` – ` · the filesystem/Obsidian set
  `\ : * ? " < > | # ^ [ ]` (and `/`, which the filesystem forbids outright).
- Length: aim ≤ 70 characters, hard stop 100, counted on the name **without its extension**.
  The cap counts **characters**, not bytes — which matters the moment a title is not Latin.

## Vocabularies — closed; extend the list here, never invent inline

**Scope:** whatever your projects and areas are. Keep it short, proper-noun-cased, and
written down — an open scope slot is indistinguishable from a title word, and the moment it
is ambiguous the grammar stops being checkable.

**Type:** `Research` · `Plan` · `Log` · `ADR` · `Lesson` · `Audit` · `Reference` · `Tool` ·
`Transcript` · `Summary` · `Status` · `Brief` · `Spec` · `Note`. A team working in another
language keeps an alias per Type and uses it in that language's folders — the example config
does exactly this for a Russian diary tree (`Выжимка`, `Расшифровка`).

## Default genre per folder

A folder that only ever holds one genre implies it, and writing it into the name is then
noise. This table is the reason `redundant-type` is a check at all. **No entry means: always
write the Type.**

| Folder | Implicit Type |
|---|---|
| `notes/research/` | Research |
| `notes/plans/` | Plan — a running log is the exception and writes `· Log` |
| `notes/decisions/` | ADR (the key carries it) |
| `notes/lessons/` | Lesson |
| `notes/references/` | Reference (head = the source or author) |
| `notes/tools/` | Tool (head = the tool's own name) |
| `notes/audits/` | Audit |
| `*/Transcripts/` | Transcript |
| `дневник/выжимки/` | Выжимка |
| `дневник/архив/` | Расшифровка |
| `notes/evergreen/` | none — evergreen notes carry no key and no type: `⟨Head⟩ — ⟨title⟩` |
| anything else (`notes/inbox/`, a project's `docs/`) | none — write the Type |

## Examples

    2026-09-05 Payments — reconciliation gaps in the nightly job.md   plans/ — Plan implicit, scope written
    2026-03-09 Pricing · Council — tiering options.md                 research/ — non-default genre, so it is written
    ADR-0015 Search — drop the legacy index.md                        decisions/ — series number as key
    2026-09-01 Clarity — substance-first prose editor (skill).md      tools/ — head is the tool's name
    Alan Sokal — Fashionable Nonsense.md                              evergreen/ — no key, no type
    2026-08-31 Статус.md                                              a folder whose scope is implied; mixed genres, so the type is written

## Parsing — for agents and scripts

Leading date = key. Everything before the first ` — ` = head, split on ` · ` into Scope and
Type. Trailing `(…)` = qualifier. The rest = title.

    ^(\d{4}-\d{2}-\d{2} |ADR-\d{4} |\d{2} )?(.+? — )?(.+?)( \(.+\))?\.\w+$

**This regex parses; it does not validate.** Its catch-all title group accepts
`2026-09-05-quarterly-review` as readily as a canonical name. Validation is the negative
list in `naming-lint.sh` — the enumerated ways a name goes wrong — and that asymmetry is the
single most useful thing in this bundle. See the README.

## Out of scope

Code and code-adjacent identifiers keep their stack's convention: sources, repo / branch /
worktree slugs, env vars, URLs. ALLCAPS singletons stay as they are (`README.md`,
`CLAUDE.md`, `AGENTS.md`, `*_META.md`, `INDEX.md`) — uppercase means "entry point, one per
folder"; the list lives in `is_singleton()` in the lint. Tool-generated names (screenshots,
bank statements, clinic exports) are renamed **when filed**, not before, which is why the
example config excludes an `imports/` folder from the gate rather than governing it.
Frontmatter `id:` values are stable identifiers independent of the filename — never derive
one from the other.

## When unsure

Ask what the folder's default genre is; no entry → write the Type. Ask whether the folder is
cross-project; if yes → write the Scope. Everything else is the title. Non-conforming
neighbours in a folder are legacy, not a pattern to copy.
