{ config, modulesPath, pkgs, lib, ... }:
let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
in {
  imports = [
    "${modulesPath}/image/repart.nix"
    "${modulesPath}/profiles/appliance.nix"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      # TODO Using erofs here generates a corrupted fs.
      erofs-utils = prev.erofs-utils.overrideAttrs (old: rec {
        version = "1.6";
        src =  prev.fetchurl {
          url =
            "https://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git/snapshot/erofs-utils-${version}.tar.gz";
          sha256 = "sha256-2/Gtrv8buFMrKacsip4ZGTjJOJlGdw3HY9PFnm8yBXE=";
        };
      });
    })
  ];

  # Debug
  environment.systemPackages = with pkgs; [
    # strace
  ];

  # Network config
  networking.useNetworkd = true;
  systemd.network.wait-online.enable = false;
  networking.firewall.enable = false;

  # Automatically open an admin console on the serial port.
  services.getty.autologinUser = "admin";
  security.sudo.wheelNeedsPassword = false;

  # Boot
  boot.initrd.systemd.enable = true;
  boot.loader.grub.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "console=ttyS0,115200"

    # For systemd debugging:
    #
    # "systemd.log_level=debug"
    # "systemd.journald.forward_to_console=1"
  ];

  fileSystems."/".device = "/dev/disk/by-label/nixos";
  fileSystems."/nix/store".device = "/dev/disk/by-partlabel/nix-store";

  # TODO Populate these automatically from the repart config.
  boot.initrd.availableKernelModules = [ "erofs" "squashfs" "ext4" "overlay" ];

  # See here for documentation:
  #
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/image/repart.md
  image.repart = {
    name = "image";
    partitions = {
      "esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

          "/loader/entries/nixos.conf".source = pkgs.writeText "nixos.conf" ''
              title NixOS
              linux /EFI/nixos/kernel.efi
              initrd /EFI/nixos/initrd.efi
              options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
            '';

          "/EFI/nixos/kernel.efi".source =
            "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";

          "/EFI/nixos/initrd.efi".source =
            "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = "96M";
        };
      };

      "store" = {
        storePaths = [ config.system.build.toplevel ];
        stripNixStorePrefix = true;
        repartConfig = {
          Type = "linux-generic";
          Label = "nix-store";

          Format = "squashfs";
          Minimize = "best";
        };
      };

      "root" = {
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "nixos";
          SizeMinBytes = "512M";
        };
      };
    };
  };

  users.mutableUsers = false;
  users.users.admin = {
    description = "Administrator";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    createHome = true;

    # Insecure of course.
    initialPassword = "admin";
  };

  system.stateVersion = "23.11";
}
