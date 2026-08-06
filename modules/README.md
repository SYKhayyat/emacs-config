# Emacs literate modules

The modules are split in two, and the split is the architecture:

| Group | What it is | Rule |
|-------|------------|------|
| **`essentials/`** | A good general Emacs configuration | Knows nothing about Hebrew or seforim. Delete `extras/` and this still stands on its own. |
| **`extras/`** | The personal half: Hebrew, RTL, the seforim library, the rich-footnote apparatus | Layers **on top of** essentials. |

`init.el` loads **group by group** — every `essentials/NN-*.el` in filename
order, then every `extras/NN-*.el`. So the dependency can only ever point one
way: extras may use anything essentials defines, and essentials may never
reach into extras. That is enforced by the load order rather than by everyone
remembering it.

Each module is a literate Org file tangled to `.el` — at Emacs startup on a
portable install, at **build time** on NixOS (see below).
**The `.org` files are the source of truth.** Never edit the generated `.el` —
it is overwritten on the next tangle. `.el` files are deliberately *not*
checked in: they are build output, and committing them is how a stale generated
file ends up shadowing its source.

## How extras reaches into essentials

When something in `extras/` needs to appear in a list that `essentials/` owns,
the essentials module exports an **extension point** and extras appends to it.
Nothing in extras redefines an essentials function.

| Extension point | Owner | Used by |
|-----------------|-------|---------|
| `my/ibuffer-extra-groups` | `essentials/04-navigation` | `extras/16-seforim-integration` |
| `my/pick-font` | `essentials/01-ui` | `extras/00-hebrew` (Hebrew fontset) |
| `orderless-style-dispatchers` | `essentials/02-completion` | `extras/01-hebrew-completion` (niqqud matching) |
| `dirvish-quick-access-entries` | `essentials/15-dirvish` | `extras/16-seforim-integration` |
| `org-capture-templates`, `org-tag-alist`, `org-roam-capture-templates` | `essentials/05-org`, `06-org-roam` | `extras/02-hebrew-org` |

## How they reach the running Emacs

**Portable install** (Windows, macOS, any non-Nix distro). `tools/deploy.sh`
copies this tree into the config dir. It is writable, so `init.el` tangles any
`.el` that is missing or older than its `.org` on startup, and
`essentials/24-utils` re-tangles a module when you save it. Instant edit loop.

**NixOS.** The flake's `packages.default` runs `tools/tangle.sh` **at build
time** and ships `.org` and `.el` together. The consuming home-manager module
symlinks that store path to `~/.config/emacs/modules`, read-only. Nothing
tangles at startup — `my/tangle-stale-modules` checks `file-writable-p` and
skips the directory outright.

> This replaced a staging hop: the modules used to be installed read-only to
> `~/.config/emacs/modules-src` and then `cp`'d — gated on mtime — into a
> *writable* `~/.config/emacs/modules`, because the store is read-only and
> Emacs had to write the `.el` next to the `.org`.
>
> That copy was a directory Nix did not own. It could not be rolled back or
> garbage-collected, and the sync only ever added, never deleted. Editing a
> module in place either silently won (your edit becomes the live config, the
> repo goes stale) or was silently clobbered, with nothing to tell you which.
> It also concealed its own failures: six modules sat untracked for weeks, so
> they never entered the store at all — invisible, because the writable copy
> still had them from an earlier deploy.
>
> Tangling at build time removes the reason the hop existed.

The loader itself (`../init.el`, `../early-init.el`) is the same file on every
machine — symlinked from the store on NixOS, copied by `deploy.sh` elsewhere.
One copy, so the Nix and portable paths cannot drift.

## The modules

### `essentials/` — the general config

```
00-core         01-ui           02-completion   03-editing      04-navigation
05-org          06-org-roam     07-latex        08-typst        09-context
10-markdown     11-pdf          12-programming  13-magit        14-projectile
15-dirvish      16-vterm        17-terminal     18-tabs         19-academic
20-local-ai     21-web-search   22-nix-system   23-hydras       24-utils
```

### `extras/` — the personal config

```
00-hebrew               01-hebrew-completion    02-hebrew-org
03-hebrew-typesetting   04-hebrew-scholarship   05-rich-footnotes
06-torah-search         10-seforim-core         11-seforim-candidates
12-seforim-search       13-seforim-extras       14-seforim-mefarshim
15-seforim-dream        16-seforim-integration  17-hydras
```

The loader globs `NN-*.el` per group in filename order — there is no list to
maintain in code, so the two above are documentation only. Drop in a
`25-foo.org` under either group and it loads.

## Adding a module

1. Decide the group by one question: **would someone who does not read Hebrew
   want this?** Yes → `essentials/`. No → `extras/`.
2. Number it with a zero-padded prefix; the loader orders by it *within* the group.
3. The first source block must start with
   `;;; NN-name.el --- … -*- lexical-binding: t; -*-` and the file must end with
   `(provide 'NN-name)`. Both must match the filename.
4. If it needs to gate on a capability, add a case to `my/module-enabled-p` in
   `init.el`. Gate on the **name** (`"vterm"`), never the number — renumbering
   must not silently un-gate a module.
5. **`git add` it.** A flake copies the *git tree* to the store, so an untracked
   `.org` does not exist on any machine but the one it was written on.

## Renumbering a module — read this first

A module's identity **is** its ordering prefix. `10-seforim-core.org` tangles to
`10-seforim-core.el`, provides `10-seforim-core`, and dependents say
`(require '10-seforim-core)`. Renumbering therefore renames the module and
invalidates every reference to it.

That is not hypothetical. The essentials/extras split renumbered most of the
tree; five modules kept requiring the pre-split names (`14a-seforim-core` and
friends). Nothing provided those, `require` signalled, `init.el` caught it in
`condition-case`, and **1,569 of the seforim system's 1,775 lines stopped
loading.** No crash, no failing build. The only symptom was
`M-x seforim-mefarshim` quietly not existing.

So: after any rename, run

```sh
bash tools/check-modules.sh
```

`tools/check-modules.sh` verifies that

- every `provide` matches its filename, and no feature is provided twice
- every explicit `:tangle` target and `;;; name.el ---` header matches too
- **every local `require` resolves to a module that actually exists**
- dependencies point `essentials/` → `extras/` and never back, and within a
  group only ever backwards in load order
- no orphaned `.el` is left behind by a rename
- no capability gate in `my/module-enabled-p` names a module that isn't there
- every `.org` is tracked by git

It needs no Emacs and no packages, runs in about a second, and is wired into
`nix flake check` as the `emacs-modules` check — so a rebuild now fails on
exactly the breakage described above instead of shipping it.

`tools/verify.sh` is the heavier second pass: it tangles and byte-compiles
against the real package set, which catches syntax errors and requires of
packages that aren't installed. It runs as the `emacs-bytecompile` flake check,
or `just verify-emacs` locally.

> Historical note, because it is the actual lesson: `verify.sh` *existed* the
> whole time and would have surfaced this. It ended its pipeline with
> `| grep -vE "…Cannot open load file…" || true` — filtering out the exact
> diagnostic, and pinning the exit status at 0 so it could never fail anyway.
> A verification tool that cannot report failure is not a verification tool.

## When a module doesn't load

Missing or failing modules are non-fatal: `init.el` wraps each `load` in
`condition-case` and records it in `my/load-errors`, so one broken file cannot
take the session down. On failure it now raises a `display-warning` at `:error`
level — the *Warnings* buffer pops and stays — instead of printing one line
into `*Messages*` that scrolls away unread. `M-x my/load-report` lists what
failed and why at any point in the session.
