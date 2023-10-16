{
  description = "System Configuration";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Experimental fork that creates users without Perl in the closure.
    nixpkgs.url = "github:nikstur/nixpkgs/perlless-activation";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.image = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix

        # This is only required in nikstur's nixpkgs fork.
        ./perlless.nix
      ];
    };
  };
}
