{ lib, ... }:
{

  system.rebuildable = false;

  users.users.root.initialPassword = "djodno";

  system.activationScripts.borgbackup = lib.mkForce "";
  system.activationScripts.upsSetup = lib.mkForce "";
  system.activationScripts.vmwareWrappers = lib.mkForce "";
  system.activationScripts.wrappers = lib.mkForce "";
  system.activationScripts.ldap = lib.mkForce "";
  system.activationScripts.create-test-cert = lib.mkForce "";
}
