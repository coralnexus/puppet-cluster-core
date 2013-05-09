/**
 * Gateway manifest to all Puppet classes.
 *
 * Note: This is the only node in this system.  We use it to dynamically
 * bootstrap or load and manage classes (profiles).
 *
 * This should allow the server to configure it's own profiles in the future.
 */
node default {

  Exec {
    logoutput => "on_failure",
  }

  #---

  import "*.pp"
  import "default/*.pp"
  include global::default

  #---

  resources { "firewall":
    purge => true
  }
  Firewall {
    before  => Class['coral::firewall::post_rules'],
    require => Class['coral::firewall::pre_rules'],
  }

  include coral
  include coral::firewall::pre_rules
  include coral::firewall::post_rules

  Class['global::default'] -> Class['coral']

  Exec {
    user => $coral::params::exec_user,
    path => $coral::params::exec_path
  }

  #---

  import "profiles/*.pp"

  if config_initialized and file_exists(global_param('config_common')) {
    include base
    Class['coral'] -> Class['base']

    coral_include('profiles')
  }
  else {
    $cluster_address = global_param('cluster_address')

    notice "Bootstrapping server"
    notice "Push cluster definition to: ${cluster_address}"

    include bootstrap
    Class['coral'] -> Class['bootstrap']
  }
}
