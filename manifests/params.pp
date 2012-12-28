# Class: postgresql::params
#
#   The postgresql configuration settings.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#

# TODO: add real docs

# This class allows you to use a newer version of postgres, rather than your
# system's default version.
#
# If you want to do that, note that it is important that you use the '->',
# or a before/require metaparameter to make sure that the `params`
# class is evaluated before any of the other classes in the module.
#
# Also note that this class includes the ability to automatically manage
# the yumrepo resource.  If you'd prefer to manage the repo yourself, simply pass
# 'false' or omit the 'manage_repo' parameter--it defaults to 'false'.  You will
# still need to use the 'params' class to specify the postgres version
# number, though, in order for the other classes to be able to find the
# correct paths to the postgres dirs.

class postgresql::params(
    $version               = '9.1.6',
    $manage_package_repo   = false,
    $package_source        = undef,
) {
  $user                         = 'pe-postgres'
  $group                        = 'pe-postgres'
  $ip_mask_deny_postgres_user   = '0.0.0.0/0'
  $ip_mask_allow_all_users      = '127.0.0.1/32'
  $listen_addresses             = 'localhost'
  $ipv4acls                     = []
  $ipv6acls                     = []
  # TODO: figure out a way to make this not platform-specific
  $manage_redhat_firewall       = false

  # MM 12-28-2012 - for PE we actually don't want any of this
  #if ($manage_package_repo) {
  #    case $::osfamily {
  #      'RedHat': {
  #         $rh_pkg_source = pick($package_source, 'yum.postgresql.org')

  #         case $rh_pkg_source {
  #           'yum.postgresql.org': {
  #              class { "postgresql::package_source::yum_postgresql_org":
  #                version => $version
  #              }
  #           }

  #           default: {
  #             fail("Unsupported package source '${rh_pkg_source}' for ${::osfamily} OS family. Currently the only supported source is 'yum.postgresql.org'")
  #           }
  #         }
  #      }

  #      default: {
  #        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports osfamily RedHat and Debian")
  #      }
  #    }
  #  }


  # This is a bit hacky, but if the puppet nodes don't have pluginsync enabled,
  # they will fail with a not-so-helpful error message.  Here we are explicitly
  # verifying that the custom fact exists (which implies that pluginsync is
  # enabled and succeeded).  If not, we fail with a hint that tells the user
  # that pluginsync might not be enabled.  Ideally this would be handled directly
  # in puppet.

  # 12-28-2012 MM
  # We don't need this part because we know we'll be pluginsynced, and we don't wnat
  # to use the default version anyway
  #if ($::postgres_default_version == undef) {
  #  fail "No value for postgres_default_version facter fact; it's possible that you don't have pluginsync enabled."
  #}

  #case $::operatingsystem {
  #  default: {
  #    $service_provider = undef
  #  }
  #}

  if ($::is_pe) {
    $needs_initdb        = true
    $firewall_supported  = true
    $client_package_name = 'pe-postgresql'
    $server_package_name = 'pe-postgresql-server'
    $devel_package_name  = 'pe-postgresql-devel'
    $service_name        = 'pe-postgresql'
    $version_parts       = split($version, '[.]')
    $package_version     = "${version_parts[0]}.${version_parts[1]}"
    $bindir              = '/opt/puppet/bin'
    $datadir             = "/opt/puppet/var/lib/pgsql/${package_version}/data"
    $confdir             = $datadir
    $service_status      = undef

    case $::osfamily {
      'RedHat': {
        $persist_firewall_command = '/sbin/iptables-save > /etc/sysconfig/iptables'
      }

      'Debian': {
        # TODO: not exactly sure yet what the right thing to do for Debian/Ubuntu is.
        #$persist_firewall_command = '/sbin/iptables-save > /etc/iptables/rules.v4'
      }
      'Sles': {
        # Is this even right? is Sles an OS family? Also, figure out the firewall
        #$persist_firewall_command = '/sbin/iptables-save > /etc/iptables/rules.v4'
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports osfamily RedHat and Debian")
      }
    }
  } else {
      fail("This module only works on Puppet Enterprise.")
  }

  $initdb_path          = "${bindir}/initdb"
  $createdb_path        = "${bindir}/createdb"
  $psql_path            = "${bindir}/psql"
  $pg_hba_conf_path     = "${confdir}/pg_hba.conf"
  $postgresql_conf_path = "${confdir}/postgresql.conf"
}
