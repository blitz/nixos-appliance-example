{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  nix.enable = false;
  environment.defaultPackages = [];

  # Remove perl dependencies
  programs.less.lessopen = null;
  boot.enableContainers = false;
}
