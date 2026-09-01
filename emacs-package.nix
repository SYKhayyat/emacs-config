# The Emacs binary and its package set, as a function of `pkgs' alone.
#
# This used to be a `let' binding inside default.nix, which meant it was
# reachable only from a fully-evaluated home-manager configuration.  It is
# factored out here so `nix flake check' can build the *same* Emacs the system
# installs and byte-compile the modules against it.  A verification job that
# compiles against a different package set than the one you run is not
# verifying your configuration -- it is verifying a lookalike.
#
# If the Emacs config is ever split into its own repository, this file goes
# with `default.nix' and stays here: it describes what NixOS installs, not what
# the config does.
{ pkgs }:

let
  emacs = pkgs.emacs30-pgtk or pkgs.emacs30 or pkgs.emacs29-pgtk;

  # Work around an upstream nixpkgs bug on nixos-26.05: its generated GNU ELPA
  # snapshot pins `org' at 9.8.3, a version GNU ELPA never published (the
  # archive goes 9.8.1 -> 9.8.4).  Every mirror 404s for both org-9.8.3.tar and
  # org-9.8.3.tar.lz, so `nix flake check' (the bytecompile job) is red even with
  # a healthy config.  `org' is also pulled in *transitively* by org-roam, citar,
  # org-modern and ox-pandoc, so it has to be fixed here rather than just dropped
  # from the package list below.
  #
  # We re-pin it to the latest published release.  GNU ELPA keeps every *released*
  # version in its archive permanently, compressed as x.tar.lz (only the current
  # version is additionally served uncompressed), so we fetch the x.tar.lz — it
  # will not go away when a newer org lands — and decompress it with lzip, exactly
  # as nixpkgs' own fetchelpa.nix does.  `sha256' is the hash of the *decompressed*
  # tar, i.e. of the final `$out' that fetchurl verifies after postFetch.
  emacsWithOrg =
    let
      epkgs = pkgs.emacsPackagesFor emacs;
    in
    (epkgs.overrideScope (_: super: {
      org = super.org.overrideAttrs (_: {
        version = "9.8.10";
        src = pkgs.fetchurl {
          name = "org-9.8.10.tar";
          url = "https://elpa.gnu.org/packages/org-9.8.10.tar.lz";
          sha256 = "890a9dd5c4f1d279f6ed0b3d10670d796aaccb7fdc71a2a665cd153bec463f1d";
          postFetch = ''
            ${pkgs.lzip}/bin/lzip -d -c "$out" > "$out.uncompressed"
            mv "$out.uncompressed" "$out"
          '';
        };
      });
    }));
in
emacsWithOrg.emacsWithPackages (epkgs: with epkgs; [
  use-package dash s f seq cl-lib diminish
  doom-themes doom-modeline nerd-icons all-the-icons all-the-icons-dired pulsar shrink-path
  vertico orderless marginalia consult embark embark-consult corfu anzu deadgrep engine-mode
  undo-tree avy ace-window multiple-cursors expand-region move-text crux visual-regexp wgrep
  rainbow-delimiters goto-last-change beginend
  projectile consult-projectile dirvish
  org org-modern org-download org-roam org-roam-ui ox-pandoc citar citar-org-roam citeproc
  vterm pdf-tools jinx gptel
  # nov (EPUB) and pdf-view-restore are `use-package'd by the pdf module.  In
  # Nix mode `use-package-always-ensure' is nil, so a package that is not
  # listed here is not installed and not on the load-path -- the use-package
  # form is a silent no-op and the feature simply is not there.  Both were
  # missing, which is why opening a .epub did nothing.
  nov pdf-view-restore
  magit git-gutter git-timemachine eglot eglot-java treesit-grammars.with-all-grammars
  treesit-auto rust-mode cargo nix-mode markdown-mode typst-ts-mode yasnippet
  yasnippet-snippets editorconfig envrc helpful which-key
  gcmh hydra restart-emacs visual-fill-column
  valign focus olivetti
  # activities: the persistent-workspace layer behind 25-activities.org.  A GNU
  # ELPA package (pure Elisp, depends only on `persist'), so it builds and runs
  # the same on every OS.
  activities
  # typst-preview is an *Emacs* package, so it belongs on the Emacs
  # load-path — not in `home.packages`, where it was previously listed and
  # therefore could never be `require`d.  It talks to `tinymist preview`
  # over a websocket, hence the explicit websocket dependency.
  typst-preview websocket
])
