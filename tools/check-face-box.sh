#!/usr/bin/env bash
# Assert that the `:style none' face-box sanitizer is installed, and that every
# entry point a face spec can arrive through gets repaired.
#
# ── What this is for ──────────────────────────────────────────────────────
#
# Emacs 30 rejects `:style none' in a face box:
#
#   Invalid face box: :line-width, 1, :style, none
#
# doom-themes writes exactly that on five faces (custom-button and friends) in
# `doom-themes-base.el', and the copy of it that a *portable* install leaves in
# ~/.emacs.d/elpa is old enough to still do so.  `modules/essentials/01-ui.org'
# strips the pair at install time, which is the same thing upstream eventually
# did -- so the fix is right, but it is only right for the entry point it was
# written against.
#
# There are four, and they do not all fail the same way:
#
#   custom-theme-set-faces  stores the spec.  The failure surfaces later, during
#                           redisplay, which is why the report named whatever
#                           module happened to be loading at that moment --
#                           11-pdf and 16-seforim-integration in the report that
#                           prompted this test, neither of which mentions a face.
#   custom-set-faces        same shape, same deferred failure.
#   face-spec-set           validates *eagerly*.  This is the one that threw.
#   set-face-attribute      validates eagerly too.
#
# Byte-compiling the module (tools/verify.sh) cannot see any of this: every one
# of those calls compiles clean.  The failure is a runtime one, in a GUI session,
# in a stale package directory -- i.e. exactly the kind that a config repo has no
# other way to notice.
#
# ── The control is the part that keeps it honest ──────────────────────────
#
# A test that also passes on the broken config is worth nothing, and this repo
# has shipped one of those before: tools/verify.sh could not fail by
# construction, and a green check sat over 1,569 lines of dead elisp.  So the
# last step *removes* the advice and requires the same call to fail.  If the
# control passes, the sanitizer is not what is keeping the faces valid, and this
# test says so rather than quietly going green.
#
# Usage: check-face-box.sh          # 0 = every entry point repaired
#        EMACS=/path/to/emacs ...   # compile against a different Emacs
set -uo pipefail
EMACS="${EMACS:-emacs}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mktemp -d)"
LOG="$OUT/check-face-box.log"
PROBE="$OUT/probe.el"
trap 'rm -rf "$OUT"' EXIT

command -v "$EMACS" >/dev/null 2>&1 || { echo "no emacs on PATH (set \$EMACS)" >&2; exit 1; }

# The probe is written out rather than passed as a `--eval' string because it is
# elisp with quotes, plists and parens in it, and a shell string that long is a
# second thing that can be wrong.
cat >"$PROBE" <<'PROBE_EOF'
;;; probe.el --- is the :style none sanitizer actually installed?  -*- lexical-binding: t; -*-

(defvar my/test-failures nil)

(defun my/test-step (name fn)
  "Run FN, recording NAME as a failure when it signals."
  (condition-case err
      (progn (funcall fn) (message "  ok   %s" name))
    (error (push (format "%s: %s" name (error-message-string err)) my/test-failures)
           (message "  FAIL %s: %s" name (error-message-string err)))))

(defconst my/test-bad '(:line-width 1 :style none)
  "The spec doom-themes 2.3.0 writes, and Emacs 30 refuses.")
(defconst my/test-spec '((t (:box (:line-width 1 :style none))))
  "The same thing in the shape the store-now, validate-later entry points take.")

(defun my/test-has-none-style (tree)
  "Return non-nil when TREE still carries a `:style none' pair anywhere."
  (cond ((not (consp tree)) nil)
        ((and (eq (car tree) :style) (eq (cadr tree) 'none)) t)
        (t (or (my/test-has-none-style (car tree))
               (my/test-has-none-style (cdr tree))))))

(defun my/test-stored-clean-p (face)
  "Return non-nil when FACE's stored property list has no `:style none'.
Two of the four entry points do not validate when they are called -- they store
the spec and Emacs rejects it later, mid-redisplay -- so a call that returns
without signalling is not evidence that anything was repaired.  This looks at
what ended up on the face symbol instead."
  (not (my/test-has-none-style (symbol-plist face))))

;; `set-face-attribute' requires the face to exist, and the store-now paths are
;; easier to read back from a face we own.
(dolist (f '(my/test-face-1 my/test-face-2 my/test-face-3 my/test-face-4))
  (make-face f))

;; ── 1. The sanitizer is installed on all four entry points ────────────────
;;
;; Without this, every step below would pass on a config that has no sanitizer
;; and no working 01-ui.el -- the vacuous-green failure mode this file exists to
;; avoid.  A module that failed to load is exactly how the bug was found: the
;; report said 11-pdf, and 01-ui was never mentioned.
(defconst my/test-advice
  '((custom-theme-set-faces . my/sanitize-theme-faces-advice)
    (custom-set-faces       . my/sanitize-custom-faces-advice)
    (face-spec-set          . my/sanitize-face-spec-set-advice)
    (set-face-attribute     . my/sanitize-set-face-attribute-advice))
  "Every entry point the sanitizer must be advised onto.")

(dolist (pair my/test-advice)
  (let ((fun (car pair)) (advice (cdr pair)))
    (cond ((not (fboundp advice))
           (push (format "01-ui.el did not load: no %S" advice) my/test-failures))
          ((not (advice-member-p advice fun))
           (push (format "%S is defined but not advised onto %S" advice fun)
                 my/test-failures))
          (t (message "  ok   %S advised" fun)))))

;; ── 2. Every entry point repairs the spec instead of rejecting it ─────────
;;
;; Each call is the real function with the real bad spec.  An error is a
;; failure; so is a stored spec that still carries the pair, because Emacs
;; validates stored specs again on the way to redisplay.
(my/test-step "custom-theme-set-faces"
  (lambda ()
    (custom-theme-set-faces 'user '(my/test-face-1 ((t (:box (:line-width 1 :style none))))))))

(my/test-step "custom-set-faces"
  (lambda ()
    (custom-set-faces '(my/test-face-2 ((t (:box (:line-width 1 :style none))))))))

(my/test-step "face-spec-set"
  (lambda ()
    (face-spec-set 'my/test-face-3 my/test-spec 'face-override-spec)))

(my/test-step "set-face-attribute"
  (lambda ()
    (set-face-attribute 'my/test-face-4 nil :box my/test-bad)))

;; ── 2b. What was *stored* is repaired too ─────────────────────────────────
;;
;; `set-face-attribute' and `face-spec-set' validate on the spot, so an error is
;; proof.  `custom-theme-set-faces' and `custom-set-faces' merely store, and
;; storing a bad spec is what produced the original bug: the failure surfaced
;; later, during redisplay, and got blamed on whichever module was loading.
(dolist (face '(my/test-face-1 my/test-face-2 my/test-face-3))
  (if (my/test-stored-clean-p face)
      (message "  ok   %S stored a repaired spec" face)
    (push (format "%S still stores a :style none spec" face) my/test-failures)))

;; The pair is gone *and the rest of the box survived*.  Dropping the whole box
;; would also silence the error while losing the border, so an assertion that
;; only looks for the absence of :style would pass on the wrong fix.
(let ((box (condition-case nil (face-attribute 'my/test-face-4 :box nil 'default)
             (error :unreadable))))
  (cond ((eq box :unreadable)
         (push "set-face-attribute stored a box that cannot be read back"
               my/test-failures))
        ((and (consp box) (plist-member box :style))
         (push (format "set-face-attribute stored an unrepaired box: %S" box)
               my/test-failures))
        ((not (equal (plist-get box :line-width) 1))
         (push (format "set-face-attribute lost the line-width: %S" box) my/test-failures))
        (t (message "  ok   box kept its line-width and lost its style: %S" box))))

;; ── 3. The control: with the sanitizer off, the same call must fail ───────
;;
;; All four come off, not just `face-spec-set'.  Removing only that one was
;; tried first and it proved nothing: `face-spec-set' reaches
;; `set-face-attribute' on its way down, and the advice on *that* still repaired
;; the box, so the control reported success on a config whose fix it had just
;; disabled.  A control that cannot fail is the same defect as a test that cannot
;; fail, one layer in.
;;
;; `unwind-protect' so the advices are always restored, even if the control
;; itself goes wrong -- this probe runs in batch, but "it could only break a
;; batch run" is how a test becomes something people skip.
(when (cl-every (lambda (pair) (advice-member-p (cdr pair) (car pair)))
                my/test-advice)
  (let ((errored nil))
    (unwind-protect
        (progn
          (dolist (pair my/test-advice) (advice-remove (car pair) (cdr pair)))
          (condition-case nil
              (face-spec-set 'my/test-control '((t (:box (:line-width 1 :style none))))
                             'face-override-spec)
            (error (setq errored t))))
      (dolist (pair my/test-advice) (advice-add (car pair) :around (cdr pair))))
    (if errored
        (message "  ok   control: with the sanitizer off, the spec is rejected")
      (push "control did not fail: this test would pass on the broken config"
            my/test-failures))))

;; ── Verdict ───────────────────────────────────────────────────────────────
(if (null my/test-failures)
    (progn (message "check-face-box: every entry point repaired") (kill-emacs 0))
  (message "\ncheck-face-box: %d failure(s)" (length my/test-failures))
  (dolist (f (reverse my/test-failures)) (message "  - %s" f))
  (kill-emacs 1))
PROBE_EOF

# ── Run on a copy, and tangle it first ────────────────────────────────────
#
# Two reasons, and the second one is why this is not optional:
#
#   * The tangled .el are gitignored, so a fresh checkout has none of them and
#     the probe would fail on a file that exists only in a working tree.  CI
#     runs this from a bare `cp -r` of the source, exactly like the byte-compile
#     check.
#   * The config writes state -- savehist, recentf, org-roam, eln-cache -- into
#     `user-emacs-directory', and `user-emacs-directory' has to be the config for
#     init.el to find its modules.  Running in place therefore means every test
#     run drops a fresh history/recentf/org-roam.db into the repo it is testing.
#     A test that litters is a test people stop running.
WORK="$OUT/src"
mkdir -p "$WORK"
cp -r "$DIR/." "$WORK/"
rm -rf "$WORK/.git"
chmod -R u+w "$WORK"          # store permissions are read-only; tangle must write

# Drop compiled leftovers before tangling.  They are gitignored, so they are
# only ever artifacts -- and `cp -r' gives them the same mtime as the source
# they were built from, which means `load-prefer-newer' cannot tell them apart
# and Emacs loads the .elc.  The first version of this script failed exactly
# that way: it loaded a 01-ui.elc from six weeks earlier, found no sanitizer,
# and reported the config broken while the working tree was fixed.
find "$WORK" -name '*.elc' -delete

EMACS="$EMACS" bash "$WORK/tools/tangle.sh" >"$OUT/tangle.log" 2>&1 || {
  echo "check-face-box: tangling failed" >&2
  tail -5 "$OUT/tangle.log" >&2
  exit 1
}

# `load-prefer-newer': the working checkout can hold a stale modules/**/*.elc --
# gitignored, generated, and easy to leave behind months out of date -- and
# Emacs prefers the compiled file, so the probe would silently examine the *old*
# 01-ui.el and report whatever that did.  "Source file newer than byte-compiled
# file; using older file" is a warning, not an error, and it is exactly the kind
# of quiet substitution this repo keeps getting bitten by.  (The copy is fresh
# here, but `deploy.sh' and `verify.sh' both leave .elc behind, so the setting
# stays.)
#
# `EMACS_MODULE_GROUPS=essentials' because 01-ui lives there; init.el refuses to
# guess, and a group list inferred from the filesystem would load extras on a
# machine that has no business loading them.
EMACS_MODULE_GROUPS=essentials \
  "$EMACS" --batch \
  --eval "(setq user-emacs-directory \"$WORK/\" load-prefer-newer t)" \
  -l "$WORK/init.el" \
  -l "$PROBE" >"$LOG" 2>&1
rc=$?

# Filter for readability only.  Never for exit status, and never anything that
# could be the failure itself.
if [ "${VERBOSE:-0}" = "1" ]; then
  cat "$LOG"
else
  grep -E "^  (ok|FAIL|note)|^check-face-box|^ *-" "$LOG" || true
fi

if [ "$rc" -ne 0 ]; then
  echo >&2
  echo "check-face-box: FAILED (see above; VERBOSE=1 for the full log)" >&2
  exit 1
fi
