{
  description = "Shaul's portable literate Emacs configuration — one config, every OS";

  # This repo is deliberately consumable two ways:
  #
  #   * As a flake input (NixOS). `packages.default` is the config with every
  #     module already tangled, so the consumer symlinks a store path and
  #     nothing is written at runtime.
  #   * As a plain checkout (Windows, macOS, any distro). `tools/deploy.sh`
  #     copies it into place and Emacs tangles on first launch.
  #
  # Nix is the *distribution* mechanism, not a dependency. Nothing here needs
  # Nix to run.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # ── The config, pre-tangled ──────────────────────────────────────────
      #
      # Tangling is a BUILD step here, not a startup step, and that is the
      # whole point of consuming this as a flake input.
      #
      # The old arrangement staged the modules read-only in the store and then
      # ran an mtime-gated `cp` into a writable ~/.config/emacs/modules so that
      # Emacs could tangle .el next to the .org at runtime. That copy is a
      # directory Nix does not own: it cannot roll it back, cannot GC it, and
      # never deletes from it — the sync only ever adds. Edit a module in
      # ~/.config/emacs directly and either your edit silently becomes the live
      # config while the repo goes stale, or it is clobbered with no backup,
      # and you cannot tell from the outside which happened.
      #
      # Tangling at build time deletes that whole class of problem. What the
      # consumer symlinks is immutable, complete, and pinned in flake.lock.
      packages = forAll (pkgs: rec {
        default = tangled;

        tangled =
          pkgs.runCommand "emacs-config"
            {
              nativeBuildInputs = [
                pkgs.emacs-nox
                pkgs.bash
              ];
            }
            ''
              cp -r ${self} $out
              chmod -R u+w $out
              rm -rf $out/.github

              # org-babel wants somewhere to put its cache.
              export HOME="$TMPDIR"
              bash $out/tools/tangle.sh

              # A tangle that produced nothing is a silent failure, and this
              # config has been bitten by exactly that before: tangle.sh used
              # to glob the wrong directory and report "done." having written
              # zero files.
              n=$(find $out/modules -name '*.el' | wc -l)
              [ "$n" -gt 0 ] || { echo "tangled 0 modules — refusing to ship an empty config" >&2; exit 1; }
              echo "tangled $n modules"
            '';

        # The Emacs the config expects, for consumers that want it. Keeping it
        # here rather than in the NixOS repo means the config declares its own
        # package dependencies and CI can byte-compile against the real set.
        emacs = import ./emacs-package.nix { inherit pkgs; };
      });

      # ── Checks ───────────────────────────────────────────────────────────
      checks = forAll (pkgs: {
        # Static consistency: every `provide` matches its filename, every local
        # `require` resolves, deps point essentials -> extras and never back,
        # nothing orphaned, every module tracked. No Emacs, ~1 second.
        #
        # This is the job that would have caught the post-split `require`
        # breakage that silently killed 1,569 lines of the seforim system.
        modules =
          pkgs.runCommand "check-modules" { nativeBuildInputs = [ pkgs.bash ]; }
            ''
              bash ${self}/tools/check-modules.sh ${self}/modules
              touch $out
            '';

        # Tangle + byte-compile against the real package set. Catches syntax
        # errors and requires of packages that are not installed.
        bytecompile =
          pkgs.runCommand "check-bytecompile"
            {
              nativeBuildInputs = [
                (import ./emacs-package.nix { inherit pkgs; })
                pkgs.bash
              ];
            }
            ''
              cp -r ${self} ./src
              chmod -R u+w ./src
              export HOME="$PWD/home"
              mkdir -p "$HOME"
              bash ./src/tools/tangle.sh
              bash ./src/tools/verify.sh
              touch $out
            '';
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (import ./emacs-package.nix { inherit pkgs; })
            pkgs.ripgrep
            pkgs.fd
          ];
        };
      });

      formatter = forAll (pkgs: pkgs.nixfmt-rfc-style);
    };
}
