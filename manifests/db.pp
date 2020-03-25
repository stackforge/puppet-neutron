# == Class: neutron::db
#
#  Configure the Neutron database
#
# === Parameters
#
# [*database_connection*]
#   Url used to connect to database.
#   (Optional) Defaults to 'sqlite:////var/lib/neutron/ovs.sqlite'.
#
# [*database_connection_recycle_time*]
#   Timeout when db connections should be reaped.
#   (Optional) Defaults to $::os_service_default.
#
# [*database_max_pool_size*]
#   Maximum number of SQL connections to keep open in a pool.
#   (Optional) Defaults to $::os_service_default.
#
# [*database_max_retries*]
#   Maximum db connection retries during startup.
#   Setting -1 implies an infinite retry count.
#   (Optional) Defaults to $::os_service_default.
#
# [*database_retry_interval*]
#   Interval between retries of opening a sql connection.
#   (Optional) Defaults to $::os_service_default.
#
# [*database_max_overflow*]
#   If set, use this value for max_overflow with sqlalchemy.
#   (Optional) Defaults to $::os_service_default.
#
# [*database_pool_timeout*]
#   (Optional) If set, use this value for pool_timeout with SQLAlchemy.
#   Defaults to $::os_service_default
#
# [*database_db_max_retries*]
#   (Optional) Maximum retries in case of connection error or deadlock error
#   before error is raised. Set to -1 to specify an infinite retry count.
#   Defaults to $::os_service_default
#
# DEPRECATED PARAMETERS
#
# [*database_idle_timeout*]
#   Timeout when db connections should be reaped.
#   Defaults to undef.
#
# [*database_min_pool_size*]
#   Minimum number of SQL connections to keep open in a pool.
#   (Optional) Defaults to undef.
#
class neutron::db (
  $database_connection              = 'sqlite:////var/lib/neutron/ovs.sqlite',
  $database_connection_recycle_time = $::os_service_default,
  $database_max_pool_size           = $::os_service_default,
  $database_max_retries             = $::os_service_default,
  $database_retry_interval          = $::os_service_default,
  $database_max_overflow            = $::os_service_default,
  $database_pool_timeout            = $::os_service_default,
  $database_db_max_retries          = $::os_service_default,
  # DEPRECATED PARAMETERS
  $database_idle_timeout            = undef,
  $database_min_pool_size           = undef,
) {

  include neutron::deps

  if $database_idle_timeout {
    warning('The database_idle_timeout parameter is deprecated. Please use \
database_connection_recycle_time instead.')
  }

  if $::neutron::server::database_min_pool_size or $database_min_pool_size {
    warning('The database_min_pool_size parameter is deprecated, and will be removed in a future release.')
  }

  # NOTE(spredzy): In order to keep backward compatibility we rely on the pick function
  # to use neutron::<myparam> if neutron::db::<myparam> isn't specified.
  $database_connection_real = pick($::neutron::server::database_connection, $database_connection)
  $database_connection_recycle_time_real = pick($::neutron::server::database_idle_timeout, $database_idle_timeout,
                                                $database_connection_recycle_time)
  $database_max_pool_size_real = pick($::neutron::server::database_max_pool_size, $database_max_pool_size)
  $database_max_retries_real = pick($::neutron::server::database_max_retries, $database_max_retries)
  $database_retry_interval_real = pick($::neutron::server::database_retry_interval, $database_retry_interval)
  $database_max_overflow_real = pick($::neutron::server::database_max_overflow, $database_max_overflow)

  validate_legacy(Oslo::Dbconn, 'validate_re', $database_connection_real,
    ['^(sqlite|mysql(\+pymysql)?|postgresql):\/\/(\S+:\S+@\S+\/\S+)?'])

  if $database_connection_real {

    oslo::db { 'neutron_config':
      connection              => $database_connection_real,
      connection_recycle_time => $database_connection_recycle_time_real,
      max_retries             => $database_max_retries_real,
      retry_interval          => $database_retry_interval_real,
      max_pool_size           => $database_max_pool_size_real,
      max_overflow            => $database_max_overflow_real,
      pool_timeout            => $database_pool_timeout,
      db_max_retries          => $database_db_max_retries,
    }

  }

}
