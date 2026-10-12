#!/usr/bin/env bash
# Run the ert regression suite over the real module tree.
#
# Usage: tools/test.sh                 # everything
#        tools/test.sh hebrew bidi    # only suites/tests matching these strings
#        VERBOSE=1 tools/test.sh       # full ert output
#
# WHY THIS IS NOT VERIFY.SH
# -----------------------
# tools/verify.sh byte-compiles every module and tools/check-modules.sh checks
# the tree's structural invariants.  Both pass over the entire class of defect
# this suite exists for.  The config once shipped a buffer-locality bug that
# silently corrupted every Hebrew buffer in a session, a grammar installer that
# discarded unsaved work, and a package list that one module replaced while
# another added to it -- and all three compiled clean and checked clean.
#
# Nothing here can be checked statically, because each test is about a *value*
# or an *owner* at runtime, not about the shape of the text on disk.
set -uo pipefail
EMACS="${EMACS:-emacs}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS="$DIR/tests"
[ -d "$TESTS" ] || { echo "test: no tests/ directory" >&2; exit 1; }
command -v "$EMACS" >/dev/null 2>&1 || { echo "no emacs on PATH (set \$EMACS)" >&2; exit 1; }

win() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }

ELPA="${ELPA:-$HOME/.emacs.d/elpa}"
if [ -d "$ELPA" ]; then
  PKGINIT="(progn (setq package-user-dir \"$(win "$ELPA")\")
                  (require 'package)
                  (package-initialize))"
else
  PKGINIT="(ignore)"
fi

# ert selectors are EITHER a regexp string OR a predicate.  A bare string is a
# regexp (substring match on the test name), so several patterns are joined into
# one -- ert-run-tests-batch-and-exit takes exactly one selector argument.
if [ $# -gt 0 ]; then
  # Build a regexp alternation: (niqqud|export).  ert selectors are either a
  # regexp STRING or a predicate; a form is neither, so this must be evaluated.
  SELECT_QUOTED="(concat"
  sep=""
  for a in "$@"; do
    SELECT_QUOTED="$SELECT_QUOTED$sep\"$a\""
    sep="\"|\""
  done
  SELECT_QUOTED="$SELECT_QUOTED)"
else
  SELECT_QUOTED=t
fi

# SELECT is passed via --eval as a quoted form built above; single quotes here
# keep the shell from expanding $SELECT a second time inside double quotes.
"$EMACS" --batch \
  --eval "(progn $PKGINIT)" \
  --eval "(load \"$(win "$TESTS/ert-tests.el")\" nil t)" \
  --eval "(ert-run-tests-batch-and-exit (if (stringp $SELECT_QUOTED) $SELECT_QUOTED (eval $SELECT_QUOTED)))"
exit $?