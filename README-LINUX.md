# This Emacs on Linux

How the config gets onto a Linux machine, what it needs there, and how to fix it
when it breaks. It covers **both** Linux paths:

- **NixOS** — declarative, via this repo. The recommended path.
- **Any other distro** — copy the files, packages come from MELPA.

New to Emacs itself? Read **[EMACS-PRIMER.md](EMACS-PRIMER.md)** first — it
explains `C-c`, `M-x`, buffers vs. windows, and the dozen commands that get you
through the day. What the config *does* is **[README.md](README.md)**; the
Jewish-texts system is **[README-SEFORIM.md](README-SEFORIM.md)**. This file is
only about *running it on Linux*.

The Windows machine has its own, separate config — see
`~/.emacs.d/README-WINDOWS.md` there. It is a deliberately trimmed subset and is
**not** produced from these files.

---

## 1. Which path am I on?

| | NixOS (this repo) | Other Linux (Debian, Fedora, Arch, …) |
|---|---|---|
| How it installs | flake input; `nix flake update emacs-config` then `just switch` | `bash tools/deploy.sh` |
| Emacs packages | baked into the Emacs binary by Nix, pinned by `flake.lock` | installed from MELPA on first launch |
| External tools | declared in `home.packages` | you install them (§4) |
| Config location | `~/.config/emacs/` (managed) | `~/.config/emacs/` (yours) |
| Emacs daemon | `services.emacs` starts it | start it yourself |

**Do not mix them.** On NixOS, home-manager writes `~/.config/emacs/init.el` as a
read-only symlink into the nix store; `tools/deploy.sh` tries to `cp` over that
exact path and will fail or fight it. Pick one per machine.

---

## 2. Where everything lives

```
emacs-config/                ← you are here; this is the whole config
├── flake.nix                packages.default = this repo, pre-tangled
├── emacs-package.nix        the Emacs + package set this config expects
├── init.el                  the loader — ONE copy, used on every OS
├── early-init.el            pre-GUI performance knobs
├── modules/
│   ├── essentials/*.org     the general config — 25 literate modules
│   └── extras/*.org         Hebrew + seforim — 15 literate modules
├── tools/                   tangle.sh · verify.sh · check-modules.sh · deploy.sh
├── .github/workflows/       the CI that checks the elisp on every push
└── README*.md, EMACS-PRIMER.md
```

There is exactly one copy of the loader, and every machine uses it verbatim —
NixOS symlinks it out of the store, everywhere else `deploy.sh` copies it. The
Nix and portable versions cannot drift apart because there is only one.

The home-manager wiring (`home.packages`, `services.emacs`, `recoll.conf`)
lives in the **NixOS config repo**, not here — see
`modules/home/emacs/default.nix` there. This repo knows nothing about
home-manager.

---

## 3. Install

### NixOS

This repo is consumed as a **flake input** by the NixOS config, so you don't
install it here — you bump it there:

```sh
cd ~/nixOS_config-specializations
nix flake update emacs-config   # pull the latest commit of THIS repo
just build                      # dry build first — catches evaluation errors
just switch
```

Modules are tangled **at build time** and land in `~/.config/emacs/modules` as
a read-only symlink into the store. Nothing tangles at startup, nothing is
written into `$HOME`, and the exact revision you are running is recorded in
`flake.lock` — so `git checkout` an older lock and rebuild puts back exactly the
Emacs you had.

The edit loop is therefore: **commit here, `nix flake update emacs-config`
there, `just switch`.** Slower than editing in place, and that is the trade —
you get a config you can roll back instead of a directory that drifts.

> Want the fast loop while hacking? Point the input at your working tree:
> `nix flake update emacs-config --override-input emacs-config path:/home/shaul/emacs-config`

> `justfile` hardcodes `host := "desktop"`, and `flake.nix` defines only
> `nixosConfigurations.desktop`. **For a laptop you must add `hosts/laptop/` and
> a matching `nixosConfigurations.laptop` first**, then `just switch host=laptop`.
> There is no laptop host in this repo today.

### Any other distro

```sh
bash tools/deploy.sh                 # → ~/.config/emacs (backs up what's there)
emacs                                # first launch installs from MELPA
```

`essentials/00-core` auto-detects that the packages aren't on the load-path and switches to
portable mode. Force it either way with `EMACS_PACKAGES=1` (MELPA) or `0` (use
what's installed) if the guess is ever wrong.

---

## 4. External tools

Emacs shells out to a handful of programs. **Everything degrades gracefully** —
a missing tool disables its feature, it never breaks startup. `M-x
my/report-capabilities` lists what was skipped on this machine and why.

On **NixOS these are already declared** in the NixOS repo's `modules/home/emacs/default.nix` → `home.packages`; the
table is for other distros.

| Feature | Needs | Debian/Ubuntu | Fedora | Arch |
|---|---|---|---|---|
| Search (core) | `ripgrep`, `fd` | `ripgrep fd-find` | `ripgrep fd-find` | `ripgrep fd` |
| Search inside PDFs | `ripgrep-all` | `cargo install ripgrep_all` | `ripgrep-all` | `ripgrep-all` |
| PDF viewing (`essentials/11-pdf`) | poppler + `M-x pdf-tools-install` | `libpoppler-glib-dev` | `poppler-glib-devel` | `poppler-glib` |
| Spell check (`essentials/02-completion`) | enchant + a C compiler | `libenchant-2-dev` | `enchant2-devel` | `enchant` |
| Terminal (`essentials/16-vterm`) | cmake + libvterm + cc | `cmake libvterm-dev` | `cmake libvterm-devel` | `cmake libvterm` |
| Notes (`essentials/06-org-roam`) | sqlite | `libsqlite3-dev` | `sqlite-devel` | `sqlite` |
| LaTeX (`essentials/07-latex`) | `latexmk`, `lualatex` | `texlive-full` | `texlive-scheme-full` | `texlive-meta` |
| Typst (`essentials/08-typst`) | `typst` (+ `tinymist`) | `cargo install typst-cli` | same | `typst` |
| ConTeXt (`essentials/09-context`) | `context` | `texlive-context` | `texlive-context` | `texlive-context` |
| **Markdown preview (`essentials/10-markdown`)** | **`pandoc`** | `pandoc` | `pandoc` | `pandoc` |
| **AI (`essentials/20-local-ai`)** | `ollama` for local models | [ollama.com](https://ollama.com) | same | `ollama` |
| Indexed search (`extras/15-seforim-dream`) | `recoll` | `recoll` | `recoll` | `recoll` |
| Hebrew date (`extras/04-hebrew-scholarship`) | `hdate` | `libhdate1` | `hdate` | AUR `libhdate` |
| Fast file find | `plocate` | `plocate` | `plocate` | `plocate` |
| Direnv (`essentials/12-programming`) | `direnv` | `direnv` | `direnv` | `direnv` |

> Spell checking is **English only** — the Hebrew dictionaries were removed, see
> the main README §5.

---

## 5. Editing the config

**Edit the `.org`, never the `.el`.** The `.el` is generated and will be
overwritten on the next tangle. Saving a module `.org` re-tangles it
automatically (`essentials/24-utils`), and `init.el` re-tangles anything stale at startup.

```sh
bash tools/tangle.sh 10-markdown   # tangle one module by name (any group)
bash tools/tangle.sh               # tangle all
bash tools/verify.sh               # byte-compile everything, report errors
bash tools/check-modules.sh        # module consistency — no Emacs, ~1 second
```

To add a module, drop `25-foo.org` into `modules/essentials/` or
`modules/extras/` with a matching `:tangle` header, and **`git add` it** — a
flake copies the git tree to the store, so an untracked module silently does not
exist anywhere but your own machine. The loader globs `NN-*.el` per group in
filename order — there is no list to update. Pick the group by one question:
would someone who does not read Hebrew want it?

**If you renumber a module you have renamed it.** Its feature symbol is its
filename, so every `(require 'NN-name)` pointing at it breaks — and `init.el`
catches the failure, so nothing crashes and nothing goes red. Run
`bash tools/check-modules.sh` after any rename; it is
also part of `nix flake check`, so a rebuild will now catch it for you.

On NixOS, after editing: `just switch`. Adding a *package* (not just config)
means editing the package list in `emacs-package.nix` too — it lives in its own
file so `nix flake check` can build the identical Emacs and byte-compile the
modules against it.

---

## 6. What's Linux-only here

- **`essentials/22-nix-system`** — `nixos-rebuild` / `home-manager` / GC helpers. Gated on
  the Nix tooling actually being present, so it is skipped on Debian rather than
  erroring.
- **`essentials/16-vterm`** — needs a compiled module. Gated on either a prebuilt
  `vterm-module` or cmake + a C compiler, and reached with `M-x vterm`. It defines
  no keybinding *because* it is gated: `essentials/17-terminal` (built-in shells)
  always loads, so it is the one that can own `` C-` `` on every machine.
- **`~/.recoll/recoll.conf`** — written by the NixOS repo's `default.nix` only; on other
  distros run `recollindex` yourself if you want `extras/15-seforim-dream`'s
  indexed search.
- **The eln cache** goes to `~/.cache/emacs/eln-cache` on Linux (via
  `startup-redirect-eln-cache`), keeping generated artefacts out of the config
  directory.

---

## 7. Troubleshooting

**A module didn't load.** `M-x view-echo-area-messages`, or inspect
`my/load-errors`. Almost always a missing tool from §4.

**A feature is silently absent.** `M-x my/report-capabilities` — it names each
skipped package and the program it wanted.

**Package installs fail with `…/foo-<date>.tar: Not found`** (non-Nix only). The
cached package index is stale: MELPA rebuilds daily and deletes the superseded
tarball. `M-x my/package-refresh`. The config now auto-refreshes any index older
than a week, so this should not recur.

**Hebrew search returns nothing.** Check `rg` is on `PATH` (`M-x
seforim-status`). Do **not** force a UTF-8 process coding system — the default
locale coding is what makes ripgrep match Hebrew.

**Edits to a `.el` keep disappearing.** Expected — it's generated. Edit the
`.org`.

**`just switch` fails after a module edit.** Run `just build` for the full error;
`nix fmt` and `just check` (statix + deadnix) catch most `.nix` mistakes.

**PDF buffers show raw bytes.** `pdf-tools` isn't usable, so `essentials/11-pdf` no longer
claims `.pdf` in `auto-mode-alist` — install poppler and run `M-x
pdf-tools-install`.
