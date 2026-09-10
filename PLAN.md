# PLAN — emacs-config (daily driver — small, verifiable steps only)

Worker loop: top unchecked item only, byte-compile + tangle check, commit, check off, stop.
Done (closed): #17 (plocate guard), #22 (tuned).

## Phase 1 — Foundations (verify-first infrastructure)
- [ ] #8 automated tests (tangle+bytecompile exists; add regression tests — unblocks verifying all below). (Medium)
- [ ] #6 module identity coupled to load order. (Medium)
- [ ] #12 knob downgrade 4→1MiB + duplicated GC/bidi writers. (Medium)

## Phase 2 — Correctness
- [ ] #3 daf→page off-by-one between two functions. (Medium)
- [ ] #2 hebrew-quotes pair. (Medium)
- [ ] #14 Otzaria format coupling → contract test. (Medium)
- [ ] #11 undo-tree vs built-in decision. (Medium)
- [ ] #20 typst leak, #24 key shadowing/requires.

## Phase 3 — Perf + hygiene (Low/Info)
- [ ] #7 study-log rewrite, #5 file-line O(file), #4 three large-file handlers, #21 find-file O(n), #18 ollama probe, #19 markdown sync, #15 :demand by-design (decision), #16 startup network, #13 two icon systems, #9 footnotes ×3, #10 dup headers, #23 double server (harmless — last).

## Routing rule for new issues
Daily-driver repo: correctness before perf, perf before hygiene. Any AI issue about seforim correctness jumps above perf items. See AI_ISSUE_ROUTING.md.
