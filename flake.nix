{
  description = "System Configuration";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Experimental fork that creates users without Perl in the closure.
    nixpkgs.url = "github:nikstur/nixpkgs/perlless-activation";

    nixpkgs-vanilla.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-vanilla }: {
    nixosConfigurations.image = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix

        # This is only required in nikstur's nixpkgs fork.
        ./perlless.nix
      ];
    };

    devShells.x86_64-linux.default = let
      pkgs = nixpkgs-vanilla.legacyPackages.x86_64-linux;
    in pkgs.mkShell {
      packages = let
        qemuUefi = pkgs.writeShellScriptBin "qemu-uefi" ''
          exec ${pkgs.qemu}/bin/qemu-system-x86_64 \
            -machine q35,accel=kvm -cpu host -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
            -m 4096 -serial stdio "$@"
          '';
        in [
          qemuUefi
      ];
    };
  };
}
