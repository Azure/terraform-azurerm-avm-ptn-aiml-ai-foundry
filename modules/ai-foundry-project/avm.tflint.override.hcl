# The project submodule historically always enabled a system-assigned identity.
# Keep that default for existing direct consumers while allowing them to opt out.
rule "avm_interface_managed_identities" {
  enabled = false
}