# Onboarding

Which document you need, and then the path through this config in the order
that makes it make sense.

| You are | Start at |
|---|---|
| New to Emacs itself | [`../EMACS-PRIMER.md`](../EMACS-PRIMER.md) — key notation, buffers, windows, the survival commands. Then come back. |
| Installing this on a machine | [§1](#1-install) |
| Wanting only the general half, without the Hebrew | [§2](#2-two-halves-and-taking-one) |
| About to change something | [§3](#3-the-model-in-sixty-seconds) then [§5](#5-your-first-change) |
| On Linux specifically | [`../README-LINUX.md`](../README-LINUX.md) |
| Here for the seforim system | [`../README-SEFORIM.md`](../README-SEFORIM.md) |
| Stuck | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |

---

## 1. Install

**Any machine — Windows, macOS, any distro.** Clone and deploy; packages come
from MELPA on first launch.

```sh
git clone https://github.com/SYKhayyat/emacs-config
cd emacs-config && bash tools/deploy.sh
```

**NixOS is different, and the difference matters.** The repository is a flake.
Add it as an input and symlink the *tangled* output — do **not** point
`deploy.sh` at `~/.config/emacs` there.

```nix
inputs.emacs-config.url = "github:SYKhayyat/emacs-config";

# in a home-manager module:
home.file.".config/emacs/init.el".source       = "${emacsConfig}/init.el";
home.file.".config/emacs/early-init.el".source = "${emacsConfig}/early-init.el";
home.file.".config/emacs/modules".source       = "${emacsConfig}/modules";
```

The same files run on every OS. **Only two things differ per platform**: where
the config folder goes, and how you install the external tools. Both are Step 0
and Step 1 of the README's install section.

### Verify, before you conclude anything

```
M-x my/report-capabilities
```

This is the most useful thing you can do on a new machine. jinx needs Enchant,
pdf-tools needs poppler, vterm needs cmake and a C toolchain — and a missing
system library produces a **silently absent feature**, not an error. That
command lists what was skipped here and why.

Then:

```
C-h v my/load-errors            nil is what you want
M-x seforim-status              if you are using the Hebrew half
```

## 2. Two halves, and taking one

```
modules/essentials/    a good general Emacs config. Nothing in it knows about Hebrew.
modules/extras/        Hebrew, RTL, seforim, the footnote apparatus, Torah search.
```

`init.el` loads essentials first, then extras, **so the dependency can only
point one way**. Essentials never reaches into extras; where extras needs to
appear in something essentials owns, it appends to a documented extension point.
The table of those points is in [`../modules/README.md`](../modules/README.md).

"Take separately" is meant literally, and it does not require editing anything:

```sh
EMACS_MODULE_GROUPS=essentials emacs        # the general half alone
emacs                                       # both; this is the default
```

Separators are space, comma or colon.

This matters most where the config is installed read-only. On NixOS `modules/`
is a store symlink, so the alternative to an environment variable is a commit
and a rebuild.

**To make one of them the machine's default, set the variable in the session
rather than editing `init.el`.** On NixOS/home-manager that is
`home.sessionVariables` for shells **plus** `systemd.user.sessionVariables` for
the daemon `emacsclient` talks to. Setting only one gives you an Emacs that
behaves differently depending on how you started it.

## 3. The model in sixty seconds

**Literate.** Every module is an Org file, `NN-name.org`, whose code blocks
*tangle* to `NN-name.el`. **The `.org` is the source of truth**; the `.el` is
generated and re-tangles on save.

**Self-assembling loader.** `init.el` loads *every* `NN-*.el` in each group
directory, in filename order. There is **no hand-maintained list to forget** —
drop in a new `25-foo.org` and it loads. Zero-padded numbers make the filename
sort equal the intended load order.

**Portable package sourcing, auto-detected** in `00-core`:

| Mode | Behaviour |
|---|---|
| Nix / distro | packages are already on the load-path; nothing is downloaded |
| Portable | `use-package` auto-installs from MELPA — the same config bootstraps itself anywhere |

Force it with `EMACS_PACKAGES=1` (portable) or `0` (nix).

> **In Nix mode, a package that is not in `emacs-package.nix` is silently
> absent.** `use-package-always-ensure` is nil, so the form is a no-op and the
> feature is simply not there, with no error. If a feature does nothing on
> NixOS, check that list first.

**Capability-gated, not OS-gated.** `00-core` provides `my/package-usable-p`,
and modules gate **individual `use-package` forms** on it — per package, not per
module. So one missing system library costs you one feature rather than a whole
file.

**Resilient.** A module that fails to load is caught, logged to
`my/load-errors`, and reported after startup. It never takes the config down —
which is also why a broken module looks like a missing feature.

**Fast.** `early-init.el` raises the GC ceiling and neutralises the
file-name-handler during startup, then restores both. Native compilation is
enabled when a toolchain is present.

## 4. Find your way around

```
modules/essentials/
  00-core        the loader, package mode detection, my/package-usable-p
  01-ui  02-completion  03-editing  04-navigation
  05-org  06-org-roam
  07-latex  08-typst  09-context  10-markdown  11-pdf
  12-programming  13-magit  14-projectile
  15-dirvish  16-vterm  17-terminal  18-tabs
  19-academic  20-local-ai  21-web-search  22-nix-system
  23-hydras  24-utils

modules/extras/
  00-hebrew  01-hebrew-completion  02-hebrew-org
  03-hebrew-typesetting  04-hebrew-scholarship
  05-rich-footnotes      the note apparatus
  06-torah-search
  10..16-seforim-*       the seforim system
  17-hydras
```

Two more places worth knowing:

- [`../modules/README.md`](../modules/README.md) — the extension points extras
  uses to reach into essentials, how modules reach the running Emacs, adding a
  module, and **renumbering one, which you must read before doing**.
- §4 of the [README](../README.md#4-key-bindings-youll-actually-use) — the
  bindings you will actually use.

## 5. Your first change

### The loop

Open the `.org`, edit, save. It re-tangles automatically
(`my/auto-tangle-module`). Restart Emacs, or evaluate what you changed.

By hand:

```sh
bash tools/tangle.sh          # .org -> .el
bash tools/check-modules.sh   # consistency, ~1 second, no Emacs needed
bash tools/verify.sh          # byte-compile against the installed packages
nix flake check               # all of the above, hermetically — what CI runs
```

### The eight rules

From [README §8](../README.md#8-design-principles-if-youre-extending-it),
because they are enforced by the checks rather than merely requested:

1. **Pick the group by one question:** would someone who does not read Hebrew
   want this? Yes → `essentials/`. No → `extras/`.
2. **Essentials must never reference extras.** If extras needs to appear in an
   essentials-owned list, essentials exports an extension point and extras
   appends to it.
3. **Edit `.org`, never `.el`.** The first source block must start with
   `;;; NN-name.el --- … -*- lexical-binding: t; -*-`, and the file must
   `(provide 'NN-name)` matching its filename.
4. **Don't hardcode `:ensure t`.** Modules inherit `use-package-always-ensure`;
   built-ins get `:ensure nil`. AUCTeX is the one special case — its package
   name is not its feature name; see `07-latex`. **And add the package to
   `emacs-package.nix`**, or it will be silently missing on NixOS.
5. **Guard OS-specific code** with `(when (eq system-type 'windows-nt) …)`.
6. **Gate on the module name, not its number**, in `my/module-enabled-p`.
7. **Keep startup cheap** — defer with `use-package` (`:defer` / `:hook` /
   `:bind`).
8. **Don't claim what you haven't run.** A comment saying a preamble gives you
   ten parallel note blocks is a promise; if nobody compiled it, it is a guess
   wearing a promise's clothes.

Rules 3, 4 and 6 are the ones people break first, and 4 is the one whose failure
is invisible.

### Adding a module

`init.el` finds it automatically — there is nothing to register. What has to be
right is mechanical, and `check-modules.sh` checks all of it: the header line,
the matching `(provide 'NN-name)`, and a zero-padded number.

[`../modules/README.md`](../modules/README.md) has the full recipe.

### Renumbering a module

**Read *Renumbering a module* in [`../modules/README.md`](../modules/README.md)
before you do this.** It is the one operation in this repository with a proven
silent failure mode.

## 6. Why `check-modules.sh` exists

Worth knowing on day one, because it is the shape of failure this config is
prone to.

The essentials/extras split renumbered every module and left five of them
`require`-ing the pre-split feature names. Nothing provided those, `require`
signalled, `init.el` caught it in its `condition-case` — and **1,569 of the
seforim system's 1,775 lines silently stopped loading. For weeks. With a green
build**, because nothing anywhere ran over the elisp.

So there are now two CI jobs:

- **`modules`** — `check-modules.sh`, cheap, deterministic, on every push. If
  the expensive one ever becomes annoying, drop that one to a schedule; **do not
  drop this one.**
- **`bytecompile`** — `nix flake check`, which builds a full Emacs package set.

The generalisation, which applies well beyond this repository: **the config's
own resilience is what hid the failure.** Catching a module's error so it cannot
take the session down is right, and it means a load failure looks exactly like a
feature nobody wrote.

### Green locally is not evidence

CI builds hermetically through Nix, headless, with the Emacs the flake pins. A
local Emacs that is newer, graphical, or has packages installed system-wide will
accept code CI rejects — a function that arrived in a later Emacs, or one that
only exists in a build with graphics support.

Run `nix flake check` before believing a change is safe.

---

## Where to go next

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — symptom-first, starting with the
  three commands that ask the running Emacs.
- [`../README.md`](../README.md) — the full reference: install per platform, the
  module map, key bindings, the note apparatus, spell checking.
- [`../modules/README.md`](../modules/README.md) — extension points, adding a
  module, renumbering.
- [`../README-LINUX.md`](../README-LINUX.md) — the Linux paths and what is
  Linux-only.
- [`../README-SEFORIM.md`](../README-SEFORIM.md) — the seforim system in depth.
- [`../EMACS-PRIMER.md`](../EMACS-PRIMER.md) — if the key notation is still
  opaque.
