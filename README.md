# Archived — this config now lives at [SYKhayyat/emacs-config](https://github.com/SYKhayyat/emacs-config)

This repository is read-only. Development continued in
**[emacs-config](https://github.com/SYKhayyat/emacs-config)** from 2026-08-06, and
**every commit that was here is now reachable from there** — both of this
repository's histories (`master` and `org-modules`, which had separate roots) were
merged in as parents, so nothing was lost and nothing needs to be fetched from here.

Go to [emacs-config](https://github.com/SYKhayyat/emacs-config) for the current
config, the documentation, and the flake.

---

## What was here

| Branch | What it held |
|--------|--------------|
| `master` | The original single-file config: `config.org` tangling to `config.el`, with `elpa/`, `eln-cache/` and runtime state committed alongside it. Last touched 2026-03-23. |
| `modular` | The first split into numbered modules. Last touched 2026-07-09. |
| `org-modules` | The literate rewrite: 34 `NN-name.org` modules, the portable/Nix auto-detecting loader, and the seforim system. Last touched 2026-07-30. This is the branch the successor grew out of. |

## Why it moved

The successor repo is a flake with CI, a static consistency check over the module
tree, and the modules split into `essentials/` (a general Emacs config that knows
nothing about Hebrew) and `extras/` (Hebrew, RTL, and the seforim system layered on
top). It is also, unlike this repository, checkout-able on Linux: `init.el` and
`early-init.el` were committed here with the symlink file mode, so `git clone`
failed on any case-sensitive filesystem.
