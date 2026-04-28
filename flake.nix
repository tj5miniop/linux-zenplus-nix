{
  description = "Linux-TKG Kernel Flake with BORE & CachyOS patches";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      tkgKernel = pkgs.linux_latest.override {
        argsOverride = rec {
          name = "linux-tkg";
          version = "7.0.2";
          src = pkgs.fetchurl {
            url = "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${version}.tar.xz";
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
        };

        kernelPatches = [
          {
            name = "bore-scheduler";
            patch = ./patches/01-bore.patch;
          }
          # Add further patches manually to ensure strict application order
        ];

        structuredExtraConfig = with pkgs.lib.kernel; {
          SCHED_BORE = yes;
          SCHED_AUTOGROUP = no;
        };

        ignoreConfigErrors = true;
      };

    in {
      packages.${system}.default = tkgKernel;

      overlays.default = final: prev: {
        linuxPackages_tkg = prev.linuxPackagesFor tkgKernel;
      };
    };
}