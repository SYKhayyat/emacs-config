# PLAN — emacs-config

**Worker loop: top unchecked item only. Byte-compile + tangle check, commit, check
off, stop.** One item per session unless it is genuinely trivial.

## What this config is FOR

Decided 2026-10-11, from the actual contents of `~/Documents/siach_shai/b_typed`:

1. **Type and edit Hebrew Org at volume** — 689 `.org` files, 29,040 footnotes,
   headings to level 9. This is the daily work.
2. **Search it** — `C-c s` niqqud-insensitive isearch, `rg`/`rga` over 28,827
   library files, `fd` by name.
3. **Code, occasionally.**
4. **Publish, occasionally** — proven once: `tavshil_basar.pdf` (April 2026).
   `sikkum_basar_chalav.org` (8 levels, 239 footnotes) is the next one and it
   currently does not compile.

Judgement calls follow from this. Publishing is real but not daily, so the
publishing layer is kept and repaired rather than deleted. Otzaria (#27) serves a
want that was never stated and has no corpus installed.

## Landed

- `1699866` — Hebrew LaTeX export: list depth, `\footnote`-in-heading, and
  `article-hebrew` auto-selection. `sikkum_basar_chalav.org` now compiles
  (exit 0, clean PDF). #33 partially fixed.

---

## Phase 0 — Stop the data loss

Unattended data loss outranks everything. All three are small.

- [ ] **#35** `treesit-auto 'prompt` reverts unsaved buffers with `noconfirm=t` on
      any non-Nix machine missing a grammar. **Fix: `(setq treesit-auto-install nil)`.**
      One line.
- [ ] **#38** auto-save, lockfiles and backups all off — a crash loses every
      unsaved buffer. One line in `01-ui`.
- [ ] **#31** `.java` errors on open or blocks on a 100 MB JDT download. Two
      conflicting hooks on `java-mode-hook`, no capability gate.

## Phase 1 — Foundations (verify-first)

- [ ] **#8** automated tests. Everything below is verified by hand right now;
      this is what stops the next silent regression.
- [ ] **#6** module identity coupled to load order (see #47).
- [ ] **#12** `read-process-output-max` silently downgraded 4 MiB → 1 MiB.
- [ ] **New: extend `tools/check-modules.sh`** to assert every `=NN-name=`
      reference in an `.org` resolves to a real module. Three are already stale
      (`18-tabs.org` names a nonexistent `05-navigation` twice; `17-hydras.org`
      advertises a commented-out row). Cheapest high-leverage line in the repo.

## Phase 2 — Hebrew correctness

Named requirements: English LTR *and* pure Hebrew RTL, with footnotes, lists and
deep headers.

- [ ] **#32** `C-c B` uses `setq` on `bidi-display-reordering`, which is **not
      buffer-local** — one keystroke corrupts every Hebrew buffer in the session.
      Fix: `setq-local`.
- [ ] **#41** every prose mode forced RTL unconditionally. Your English
      `README.md` opens with punctuation on the wrong margin, no per-file
      override. `my/bidi-direction` exists to solve this and is never read.
- [ ] **#34** three large-file handlers, three thresholds; the Hebrew one
      hardcodes 5 MB and disables bidi reordering. Use `my/large-file-size`.
- [ ] **#45** `org-footnote-new` advice injects stray U+200F into prose on 2 of 3
      exits — invisible characters accumulate in RTL documents.
- [ ] **#44** bigfoot nesting rule documented three times, enforced nowhere.

## Phase 3 — Finish publishing

Three bugs each independently block `sikkum_basar_chalav.org`.

- [ ] **#33** *(partially fixed)* the `article-hebrew` class template's `[EXTRA]`
      body is still not emitted — `\babelfont` appears 0 times in the export even
      though `[PACKAGES]` works. Fix is proven; the Org-supported wiring is not.
- [ ] **#56** `\hypersetup` emitted before `\begin{document}` — breaks **every**
      Org→PDF export.
- [ ] **#57** blank line inside a footnote body = `\par` in `\footnote`. Survey
      how many of the 29,040 footnotes are affected before choosing fix.
- [ ] **#46** `@@latex:` fragments leak into Markdown export; no Typst/ConTeXt Org
      backend exists despite documented three-backend parity.

## Phase 4 — Ownership (the architecture)

**#47 is the parent.** Load order is the override mechanism and it is decided by a
filename digit. Five confirmed instances. Polishing anything below this line is
polishing the loser.

- [ ] **#47** no ownership model. *(Do the four below; they are the fix.)*
- [ ] **#48** two modules own the default face. The portable path picks
      `"JetBrains Mono"` — **not installed here** — so it chooses DejaVu at height
      90, then loses to a generated `99-local-fonts.el` that is not in this repo.
- [ ] **#49** `17-terminal` arms `tab-line-mode` from `shell-mode-hook`, replacing
      the workspace `tab-bar`. **Live at runtime**, unlike every other instance.
- [ ] **#50** ~14 undeclared `C-c` families. `M-g` split across two modules with no
      table to keep them consistent.
- [ ] **#51** global crux `C-a`/`C-k` defeated by `visual-line-mode` in 7 places,
      and crux's escape hatch was bound too — the decision was never made.

## Phase 5 — Delete what serves no want

Pure deletions, no dependencies. Do these *after* Phase 0–4 so the config is
coherent before shrinking.

- [ ] **#54** `19-academic`: zero-byte `.bib`, empty roam dir, and Org 9.8 ships
      `oc.el` natively. `ox-pandoc` is required by nothing.
- [ ] **#55** `09-context` reimplements `07-latex`; the typst/context view fns are
      character-for-character identical.
- [ ] **#53** `23-hydras` is entirely mirrors. `hydra-roam`'s 7 rows are all owned
      by `06-org-roam`; `hydra-writing` is a 3-head hydra slower than its own keys.
- [ ] **#52** tab hydra: 8 of 19 rows re-project bindings which-key already shows.
      `18-tabs` is a view over `04-navigation`, not a module.
- [ ] **#27** decide on Otzaria (1117 lines). **Not a deletion** — the corpus is
      one command away and the code is correct if installed. Gate it (see #26).

## Phase 6 — The menu tells the truth

- [ ] **#26** 8 of 24 hydra heads are inert without the Otzaria corpus.
- [ ] **#25** `seforim-find-plocate` ignores the prefix arg while the module
      docstring claims every search command honours `C-u`.
- [ ] **#28** `hdate` (not installed), EPUB head (0 files on disk), `bigfoot`
      (not installed) — install or remove each.
- [ ] **#29** prefer Noto Serif Hebrew over David CLM, expressed in config.

## Phase 7 — Startup and per-buffer cost

- [ ] **#36** ~4.3 s of eager loads from 24 `:demand t` forms that defeat
      `use-package-always-defer`.
- [ ] **#42** `envrc-global-mode` runs a blocking `direnv` call in the mode hook.
- [ ] **#43** per-buffer costs: `git-gutter` `git diff` every 0.5 s, org-roam
      SQLite query per completion popup, redundant `stat`, tab-line buffer walk.
- [ ] **#40** `eglot-autoshutdown t` restarts the LSP on every workspace switch.
- [ ] **#39** per-mode features hooked with no capability check (systematic class).

## Phase 8 — Hygiene

- [ ] #16 startup network, #19 markdown sync, #20 typst process leak,
      #13 two icon systems, #10 duplicate org headers, #7 study-log rewrite,
      #5 file-line O(file), #2 hebrew-quotes pair, #3 daf→page off-by-one,
      #11 undo-tree decision, #9 footnote triplication.
- [ ] **#37** 9 confirmed cross-file overrides (partly fixed by #48/#49).
- [ ] **#30** the one SIGSEGV — *not reproduced*, cause unknown. Revisit only if
      it recurs; do not spend effort speculating.
- [ ] #23 double server-start — harmless, last.

---

## Downgraded / reclassified

- **#21** → Info. Measured: `line-number-at-pos (point-max)` is **0.83 ms** on a
  2.45 MB / 50k-line buffer, and it is skipped entirely above `my/large-file-size`.
- **#4** → duplicate of #34.
- **#15** `:demand t` is not "by design" any more — see #36, it is ~4 s of debt.
- **#33** retitled: the mechanism was real but misattributed. It is nesting
  *depth*, not heading *level count*.

## Routing

Correctness before perf, perf before hygiene. A seforim or Hebrew-correctness
issue jumps above perf items. Publishing blockers (Phase 3) outrank Phase 4+
because they block real work today; everything else in Phase 4+ is structural.

See `AI_ISSUE_ROUTING.md`.