# This class installs and configures Opencontrail Neutron Plugin.
#
# === Parameters
#
# [*api_server_ip*]
#   (Optional) IP address of the API Server
#   Defaults to $facts['os_service_default']
#
# [*api_server_port*]
#   (Optional) Port of the API Server.
#   Defaults to $facts['os_service_default']
#
# [*contrail_extensions*]
#   (Optional) Array of OpenContrail extensions to be supported
#   Defaults to $facts['os_service_default']
#   Example:
#
#     class {'neutron::plugins::opencontrail' :
#       contrail_extensions => ['ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam']
#     }
#
# [*timeout*]
#   (Optional) VNC API Server request timeout in seconds.
#   Defaults to $facts['os_service_default']
#
# [*connection_timeout*]
#   (Optional) VNC API Server connection timeout in seconds.
#   Defaults to $facts['os_service_default']
#
# [*package_ensure*]
#   (Optional) Ensure state for package.
#   Defaults to 'present'.
#
# [*purge_config*]
#   (Optional) Whether to set only the specified config options
#   in the opencontrail config.
#   Defaults to false.
#
class neutron::plugins::opencontrail (
  $api_server_ip       = $facts['os_service_default'],
  $api_server_port     = $facts['os_service_default'],
  $contrail_extensions = $facts['os_service_default'],
  $timeout             = $facts['os_service_default'],
  $connection_timeout  = $facts['os_service_default'],
  $package_ensure      = 'present',
  $purge_config        = false,
) {

  include neutron::deps
  include neutron::params

  $contrail_extensions_real = $contrail_extensions ? {
    Hash    => join(join_keys_to_values($contrail_extensions, ':'), ','),
    default => join(any2array($contrail_extensions), ','),
  }

  package { 'neutron-plugin-contrail':
    ensure => $package_ensure,
    name   => $::neutron::params::opencontrail_plugin_package,
    tag    => ['openstack', 'neutron-package'],
  }

  ensure_resource('file', '/etc/neutron/plugins/opencontrail', {
    ensure => directory,
    owner  => 'root',
    group  => $::neutron::params::group,
    mode   => '0640'}
  )

  if $facts['os']['family'] == 'Debian' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path  => '/etc/default/neutron-server',
      match => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line  => "NEUTRON_PLUGIN_CONFIG=${::neutron::params::opencontrail_config_file}",
      tag   => 'neutron-file-line',
    }
  }

  if $facts['os']['family'] == 'Redhat' {
    file { '/etc/neutron/plugin.ini':
      ensure  => link,
      target  => $::neutron::params::opencontrail_config_file,
      require => Package[$::neutron::params::opencontrail_plugin_package],
      tag     => 'neutron-config-file',
    }
  }

  resources { 'neutron_plugin_opencontrail':
    purge => $purge_config,
  }

  neutron_plugin_opencontrail {
    'APISERVER/api_server_ip':       value => $api_server_ip;
    'APISERVER/api_server_port':     value => $api_server_port;
    'APISERVER/contrail_extensions': value => $contrail_extensions_real;
    'APISERVER/timeout':             value => $timeout;
    'APISERVER/connection_timeout':  value => $connection_timeout;
  }
}
