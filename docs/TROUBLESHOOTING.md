# Troubleshooting

Symptom first.

Three commands answer most of it, and all three ask the **running Emacs**
rather than a document:

```
M-x view-echo-area-messages     what happened during startup
M-x my/report-capabilities      what was skipped here, and why
M-x seforim-status              is the seforim system actually wired up
```

Plus one variable worth knowing by name:

```
C-h v my/load-errors            every module that failed to load, and its error
```

A module that fails to load is **caught, logged and reported after startup** —
it never takes the config down. That is deliberate, and it is also why a broken
module looks like a missing feature rather than an error.

---

## Contents

- [The first thing to check](#the-first-thing-to-check)
- [A feature does nothing](#a-feature-does-nothing)
- [Modules and loading](#modules-and-loading)
- [Editing the config](#editing-the-config)
- [Packages](#packages)
- [NixOS](#nixos)
- [Windows](#windows)
- [Hebrew, RTL and seforim](#hebrew-rtl-and-seforim)
- [Fonts](#fonts)
- [Spell checking](#spell-checking)
- [Startup speed](#startup-speed)
- [The checks and CI](#the-checks-and-ci)

---

## The first thing to check

Almost every "this does not work" here is one of four things, and they are
distinguishable in about a minute:

| Ask | If it says |
|---|---|
| `C-h v my/load-errors` | non-nil — **a module failed**, and its error is right there |
| `M-x my/report-capabilities` | your feature is listed as skipped — **a system library is missing** |
| Are you on NixOS? | a package missing from `emacs-package.nix` is **silently absent**, with no error at all |
| Did you edit a `.el`? | it is generated; your edit was overwritten |

The third is the one that costs people the most time, because there is nothing
to see. See [NixOS](#nixos).

## A feature does nothing

### It is not an error, it is an absence

Two mechanisms produce a feature that is simply not there, neither of which
signals:

**Capability gating.** jinx needs Enchant, pdf-tools needs poppler, vterm needs
cmake and a C toolchain. `00-core` provides `my/package-usable-p`, and modules
gate individual `use-package` forms on it — **per package, not per module**. So
one missing library removes one feature, not a whole module.

```
M-x my/report-capabilities
```

lists what was skipped here and why. That is the authoritative answer.

**Nix mode.** See [NixOS](#nixos). In that mode
`use-package-always-ensure` is nil, so a `use-package` form for a package that
is not in `emacs-package.nix` is a **no-op** rather than an install.

### A whole group of features is missing

Check which module groups actually loaded:

```sh
EMACS_MODULE_GROUPS=essentials emacs        # the general half alone
emacs                                       # both; the default
```

If `EMACS_MODULE_GROUPS` is set somewhere in your environment — a shell profile,
`home.sessionVariables`, `systemd.user.sessionVariables` — you may be running
half the config without meaning to.

Note the split: on NixOS the daemon that `emacsclient` talks to reads
`systemd.user.sessionVariables`, **not** your shell's. Setting it in only one
place gives you a config that behaves differently under `emacs` and
`emacsclient`, which is a confusing afternoon.

## Modules and loading

### A module did not load

```
M-x view-echo-area-messages
C-h v my/load-errors
```

Usually a missing package or system library. The error text names it.

### 1,569 lines stopped loading and nothing said so

This happened, and it is why `tools/check-modules.sh` exists.

The essentials/extras split renumbered every module and left five of them
`require`-ing the pre-split feature names. Nothing provided those, `require`
signalled, `init.el` caught it in its `condition-case` — and **1,569 of the
seforim system's 1,775 lines silently stopped loading, for weeks, with a green
build**, because nothing anywhere ran over the elisp.

```sh
bash tools/check-modules.sh     # ~1 second, no Emacs needed
```

It runs in CI on every push. If you are about to renumber anything, read
*Renumbering a module* in [`modules/README.md`](../modules/README.md) first.

### I added a module and it is not loading

`init.el` loads **every** `NN-*.el` in each group directory, in filename order.
There is no hand-maintained list, so the causes are mechanical:

1. **The `.el` does not exist yet.** It is tangled from the `.org`. Run
   `bash tools/tangle.sh`, or open the `.org` and save it.
2. **The header line is wrong.** The first source block must start with
   `;;; NN-name.el --- … -*- lexical-binding: t; -*-`.
3. **The `provide` does not match the filename.** The file must
   `(provide 'NN-name)` with `NN-name` matching exactly.
4. **The number is not zero-padded.** Zero-padded numbers are what make the
   filename sort equal the intended load order.

`check-modules.sh` catches all four.

### A module is gated off

`my/module-enabled-p` in `init.el` matches on the module **name, not its
number**, deliberately — so renumbering cannot silently un-gate anything. If a
module is disabled, its name is in that gate.

## Editing the config

### My edits to a `.el` file keep disappearing

**Expected.** `.el` is generated. The `.org` is the source of truth, and it
re-tangles on save via `my/auto-tangle-module`.

Edit the `.org`.

### A module is in a strange state

Delete its `.el`. It re-tangles from the `.org` on next start.

### Tangling by hand

```sh
bash tools/tangle.sh          # .org -> .el
bash tools/verify.sh          # byte-compile against the installed packages
bash tools/check-modules.sh   # consistency, no Emacs needed
nix flake check               # all of the above, hermetically
```

## Packages

### `:ensure t` did not install something

Do not hardcode `:ensure t`. Modules inherit `use-package-always-ensure`;
built-ins get `:ensure nil`.

AUCTeX is the one special case — its package name is not its feature name. See
`07-latex`.

### Which package mode am I in?

Auto-detected in `00-core`:

- **Nix/distro mode** — packages are already on the load-path, nothing is
  downloaded.
- **Portable mode** — a fresh machine with none of them; `use-package`
  auto-installs from MELPA.

Force it:

```sh
EMACS_PACKAGES=1 emacs      # portable
EMACS_PACKAGES=0 emacs      # nix
```

### A fresh machine is downloading everything on first launch

That is portable mode working. Packages come from MELPA on first launch; it is
slow once.

## NixOS

### A feature silently does nothing

**Check `emacs-package.nix` first.** This is the single most common NixOS
problem here.

In Nix mode `use-package-always-ensure` is nil, so a package that is
`use-package`'d but **missing from `epkgs` in `emacs-package.nix` is a no-op,
not an error**. The feature simply is not there, with nothing logged.

So: add the package to `emacs-package.nix` in the same commit as the
`use-package` form. Forgetting is invisible until someone uses the feature.

### Do not point `deploy.sh` at `~/.config/emacs` on NixOS

The repository is a flake. Add it as an input and symlink the **tangled**
output:

```nix
inputs.emacs-config.url = "github:SYKhayyat/emacs-config";

home.file.".config/emacs/init.el".source       = "${emacsConfig}/init.el";
home.file.".config/emacs/early-init.el".source = "${emacsConfig}/early-init.el";
home.file.".config/emacs/modules".source       = "${emacsConfig}/modules";
```

### I cannot edit a module — the directory is read-only

Expected on NixOS: `modules/` is a store symlink. That is also why
`EMACS_MODULE_GROUPS` exists as an environment variable rather than a list in
`init.el` — the alternative to an env var on a read-only config is a commit and
a rebuild.

To change which groups load by default, set the variable in the session:
`home.sessionVariables` for shells, **plus** `systemd.user.sessionVariables` for
the daemon `emacsclient` talks to.

### `nix flake check` fails and my machine is fine

That is the hermetic build finding something your machine's ambient state
hides. Read its log — it tangles and byte-compiles everything, which is the
expensive real gate.

## Windows

### Hebrew search returns nothing

**Do not override the process coding system on Windows.** The default locale
coding is what makes ripgrep match Hebrew. This is the specific trap on this
platform.

Then confirm `rg` is on `PATH`:

```
M-x seforim-status
```

### Where does the config folder go?

Platform-dependent, and it is Step 0 of the install section in the
[README](../README.md#step-0--where-the-config-folder-goes). Only two things
differ per platform: where the config folder lives, and how you install the
external tools.

### Something OS-specific broke on another machine

OS-specific code is supposed to be guarded:

```elisp
(when (eq system-type 'windows-nt) …)
```

An unguarded form is a bug on the other two platforms.

## Hebrew, RTL and seforim

### `M-x seforim-status` is the first stop

It reports whether the pieces are actually wired up. Use it before anything
else in this section.

### Search returns nothing

1. **Is `rg` on `PATH`?** `seforim-status` says.
2. **On Windows**, see [above](#hebrew-search-returns-nothing) — do not touch
   the process coding system.
3. **Did the seforim modules load?** `C-h v my/load-errors`. This is the module
   family that once silently lost 1,569 lines; see
   [above](#1569-lines-stopped-loading-and-nothing-said-so).

### The extras half is not there at all

`EMACS_MODULE_GROUPS` may be set to `essentials`. Everything Hebrew — RTL, the
seforim system, the rich-footnote apparatus, Torah web search — lives in
`extras/`, which layers on top.

Nothing in `essentials/` knows about Hebrew, deliberately.

### Deeper problems

[README-SEFORIM.md](../README-SEFORIM.md) is the deep dive: the search commands
under the `C-c S` hydra, the Otzaria mefarshim linking, and what each module
does.

## Fonts

### Fonts look wrong

`01-ui` picks the **first installed mono family** from a list, and
`extras/00-hebrew` does the same for Hebrew. **Missing fonts never error** —
they fall through to the next candidate, silently.

So "the font is wrong" means the one you wanted is not installed, or is not
named the way the list spells it. Check with `M-x describe-font` and install the
family you want.

## Spell checking

jinx needs **Enchant**. Without it, the `use-package` form is gated off by
`my/package-usable-p` and there is no spell checking and no error.

```
M-x my/report-capabilities
```

will list it as skipped. Install Enchant (plus the dictionaries you want) and
restart.

§6 of the [README](../README.md#6-spell-checking) has the details.

## Startup speed

`early-init.el` raises the GC ceiling and neutralises the file-name-handler
during startup, then restores both. Native compilation is enabled when a
toolchain is present.

If startup is slow:

- **First launch in portable mode** downloads from MELPA. Once.
- **Native compilation** of a fresh package set is slow once, then fast.
- **A module doing work at load time.** Modules are supposed to defer with
  `use-package` (`:defer` / `:hook` / `:bind`). One that does not is the usual
  culprit.

`M-x emacs-init-time` and the `*Messages*` buffer will point at it.

## The checks and CI

```sh
bash tools/check-modules.sh   # consistency — no Emacs needed, ~1 second
bash tools/tangle.sh          # .org -> .el
bash tools/verify.sh          # byte-compile against the installed packages
nix flake check               # all of the above, hermetically
```

CI runs two jobs:

- **`modules`** — `check-modules.sh`, on every push. Cheap and deterministic.
  **Do not drop this one.**
- **`bytecompile`** — `nix flake check`, which builds a full Emacs package set
  and is slower by a lot.

### CI is red and my machine is green

Expected more often than you would like, and the reason is worth internalising:
**your local Emacs is not CI's Emacs.**

CI builds hermetically through Nix, with whatever Emacs the flake pins, and a
headless one. A local Emacs that is newer, graphical, or has packages installed
system-wide will accept code CI rejects — a function that arrived in a later
Emacs, or one that only exists in a build with graphics support.

Green locally is not evidence. Run `nix flake check` before believing a change
is safe.

### A byte-compile warning I do not understand

`tools/verify.sh` byte-compiles against the **installed** packages, so a warning
there is about your local set. `nix flake check` compiles against the pinned
set, which is what CI enforces.

---

## When you are adding something and want to avoid all of this

The design principles in [README §8](../README.md#8-design-principles-if-youre-extending-it)
exist to prevent most of the failures on this page. The three that matter most:

1. **Edit `.org`, never `.el`.**
2. **Add the package to `emacs-package.nix`**, or it will be silently missing on
   NixOS.
3. **Don't claim what you haven't run.** A comment saying a preamble gives you
   ten parallel note blocks is a promise; if nobody compiled it, it is a guess
   wearing a promise's clothes.

## Reporting something not on this page

Include:

```
M-x emacs-version
C-h v my/load-errors
M-x my/report-capabilities
```

your OS, whether you are on the Nix path or the portable one, and the value of
`EMACS_MODULE_GROUPS` if it is set.
