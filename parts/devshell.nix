{
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    types
    ;
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    mkSubmoduleOptions
    ;
in {
  options = {
    perSystem = mkPerSystemOption (_: {
      _file = ./devshell.nix;

      options.beamWorkspace = mkSubmoduleOptions {
        devShell = {
          enable = mkEnableOption "beam-flakes devshells" // {default = true;};
          iexShellHistory = mkEnableOption "IEx shell history" // {default = true;};
          packages = mkOption {
            type = types.listOf types.package;
          };
        };
      };
    });
  };

  config = {
    perSystem = {
      config,
      pkgs,
      ...
    }: let
      cfg = config.beamWorkspace;
    in {
      beamWorkspace.devShell.packages =
        [
          cfg.packages.elixir
          cfg.packages.erlang
        ]
        ++ lib.optional cfg.devShell.languageServers.elixir cfg.packages.elixir_ls
        ++ lib.optional cfg.devShell.languageServers.erlang cfg.packages.erlang-ls;

      devShells = lib.mkIf (cfg.enable && cfg.devShell.enable) {
        default = pkgs.mkShell {
          inherit (cfg.devShell) packages;
          ERL_AFLAGS =
            if cfg.devShell.iexShellHistory
            then "-kernel shell_history enabled"
            else null;
        };
      };
    };
  };
}
