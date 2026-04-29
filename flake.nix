{
  description = "Linux-TKG Kernel Flake with BORE Scheduler and Linux Gaming Patches";

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
            sha256 = "53591a03294527a48ccb0b9e559e922df8a38554745a1206827ca751d2ca7662";
          };
        };

        kernelPatches = [
          {
            name = "Cachy BORE";
            patch = ./patches/0001-bore-cachy.patch;
          }
          {
            name = "Cgroup-VRAM";
            patch = "./patches/0001-cgroup-vram.patch";
          }
          {
            name = "glitched-base";
            patch = "./patches/0003-glitched-base.patch";
          }
          # Add further patches manually to ensure strict application order
        ];

        structuredExtraConfig = with pkgs.lib.kernel; {
          # SCHED CONFIG
          SCHED_BORE = tkgKernel.yes;
          SCHED_AUTOGROUP = pkgs.lib.mkForce no;
          # Cachy Optimisations
          CACHY = tkgKernel.yes;
          MQ_IOSCHED_ADIOS = tkgKernel.yes;
          # PREEMPT
          PREEMPT_DYNAMIC = tkgKernel.yes;
          HZ_1000 = tkgKernel.yes; #Tick Rate - Similar to TKG kernel config
          HZ = tkgKernel.freeform "1000";
          NO_HZ_IDLE = tkgKernel.yes;

          # Optimize for x86_64v3 CPU's (will update accordingly for my hardware)
          GENERIC_CPU = tkgKernel.yes;
          X86_64_VERSION = tkgKernel.freeform "3";

          # Memory Management
          TRANSPARENT_HUGEPAGE_ALWAYS = tkgKernel.yes;

          
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