{
  description = "Plutus Contract: NFT";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    lint-utils.url = "git+https://gitlab.homotopic.tech/nix/lint-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    haskellNix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:input-output-hk/haskell.nix";
    };
    plutus.url = "github:input-output-hk/plutus";
  };
  outputs = { self, nixpkgs, plutus, flake-utils, lint-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        deferPluginErrors = true;
        overlays = [
          haskellNix.overlay
          (final: prev: {
            plutus-contract-gift =

              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc8107";
                projectFileName = "stack.yaml";
                modules = [{
                  packages = {
                    marlowe.flags.defer-plugin-errors = deferPluginErrors;
                    plutus-use-cases.flags.defer-plugin-errors = deferPluginErrors;
                    plutus-ledger.flags.defer-plugin-errors = deferPluginErrors;
                    plutus-contract.flags.defer-plugin-errors = deferPluginErrors;
                    plutus-minting-policy-osc.flags.defer-plugin-errors = deferPluginErrors;
                    plutus-minting-policy-nft.flags.defer-plugin-errors = deferPluginErrors;
                    cardano-crypto-praos.components.library.pkgconfig =
                      pkgs.lib.mkForce [ [ (import plutus { inherit system; }).pkgs.libsodium-vrf ] ];
                    cardano-crypto-class.components.library.pkgconfig =
                      pkgs.lib.mkForce [ [ (import plutus { inherit system; }).pkgs.libsodium-vrf ] ];
                  };
                }];
                shell.tools = {
                  cabal = { };
                  ghcid = { };
                  hlint = { };
                  haskell-language-server = { };
                };
                shell.buildInputs = with pkgs; [
                  nixpkgs-fmt
                ];
              };
          })
        ];
        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
        flake = pkgs.plutus-contract-gift.flake { };
      in
      flake // {
        checks =
          with pkgs; flake.checks // {
            dhall-format = lint-utils.outputs.linters.${system}.dhall-format ./.;
            hlint = lint-utils.outputs.linters.${system}.hlint ./.;
            hpack = lint-utils.outputs.linters.${system}.hpack ./.;
            nixpkgs-fmt = lint-utils.outputs.linters.${system}.nixpkgs-fmt ./.;
            stylish-haskell = lint-utils.outputs.linters.${system}.stylish-haskell ./.;
          };
        defaultPackage = flake.packages."plutus-contract-nft:lib:plutus-contract-nft";
      });
}
