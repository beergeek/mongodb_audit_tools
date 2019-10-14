# @summary Manages the deployment_config Python script and associated resources.
#
# Installs, configures and manages the deployment_config Python script and service
# 
# @param enable_audit_db_ssl Boolean to determine if SSL/TLS is enabled for the Audit DB connection.
# @param enable_om_ssl Boolean to determine if SSL/TLS is enabled for the OPs Manager connection.
# @param enable_debugging Boolean to determine if debugging is enabled in the deployment_config config file.
# @param enable_kerberos_debugging Boolean to determine if the environmental variable for Kerberos debugging is
#   enabled in the sciprt's service file.
# @param audit_db_connection_string The MongoDB connection string for the Audit DB.
# @param om_api_connection_string The connection string for Ops Manager, include the user and token.
# @param deployment_configs_dir The absolute path to create the script and config files.
# @param kerberos_keytab_path The absolute path for the Audit DB user's Kerberos keytab file.
# @param kerberos_trace_path The absolute path for the Kerberos Trace File.
# @param audit_db_ssl_pem_file_path The absolute path to the SSL/TLS PEM file for the Audit DB communicaitons.
# @param audit_db_ssl_ca_file_path The absolute path to the SSL/TLS CA file for the Audit DB communications.
# @param om_api_ssl_pem_file_path The absolute path to the SSL/TLS PWM file for OPs Manager communications.
# @param om_api_ssl_ca_file_path The absolute path to the SSL/TLS CA file for OPs Manager communications.
# @param om_token The token for the OPs Manager user API access.
# @param om_username The username for the OPs Manager API access.
# @param python_path The absolute path to the Python executable.
# @param script_owner The owner of the script file.
# @param script_group The group of the script file.
# @param script_mode The permissions of the script file.
# @param audit_db_timeout The timeout for the Audit DB connection.
# @param om_api_timeout The timeout for the OPs Manager API endpoints.
# @param change_stream_pipeline An optional aggregation pipeline to perform on the change stream to include/exclude data.
# @param excluded_root_keys Comma-separated (no spaces) string list of excluded root keys from the Ops Manager dumps.
# @param cron_hour The hour to trigger the script via cron.
# @param cron_minute The minute to trigger the script via cron.
# @param cron_monthday the day of the month to trigger the script via cron.
#
# @example
#   class { 'mongodb_audit_tools::deployment_config_grabber':
#     audit_db_connection_string => 'mongodb://audit%40MONGODB.LOCAL@auditor.mongodb.local:27017/?replicaSet=repl00&authSource=$external&authMechanism=GSSAPI',
#     deployment_configs_dir     => '/data/scripts',
#     om_api_connection_string   => 'https://mongod0.mongodb.local:8443',
#     om_username                => 'loudSam',
#     om_token                   => '8ce50f02-4292-460e-82a5-236a074218aa',
#   }
#
class mongodb_audit_tools::deployment_config_grabber (
  Boolean                          $enable_audit_db_ssl,
  Boolean                          $enable_om_ssl,
  Boolean                          $enable_debugging,
  Boolean                          $enable_kerberos_debugging,
  Mongodb_audit_tools::MongoDBURL  $audit_db_connection_string,
  Mongodb_audit_tools::MongoDBURL  $om_api_connection_string,
  Stdlib::Absolutepath             $deployment_configs_dir,
  Optional[Stdlib::Absolutepath]   $kerberos_keytab_path,
  Optional[Stdlib::Absolutepath]   $kerberos_trace_path,
  Optional[Stdlib::Absolutepath]   $audit_db_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]   $audit_db_ssl_ca_file_path,
  Optional[Stdlib::Absolutepath]   $om_api_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]   $om_api_ssl_ca_file_path,
  Optional[Stdlib::Absolutepath]   $python_path,
  Optional[String[1]]              $excluded_root_keys,
  String[1]                        $om_token,
  String[1]                        $om_username,
  String[1]                        $script_owner,
  String[1]                        $script_group,
  String[1]                        $script_mode,
  Integer[1]                       $audit_db_timeout,
  Integer[1]                       $om_api_timeout,
  Optional[String[1]]              $change_stream_pipeline,  Variant[Enum['*'],Integer[0,23]] $cron_hour,
  Variant[Enum['*'],Integer[0,59]] $cron_minute,
  Variant[Enum['*'],Integer[0,31]] $cron_monthday,
) {

  if $facts['os']['family'] != 'RedHat' {
    fail('This module is for RedHat family of Linux')
  }

  if $kerberos_keytab_path and $kerberos_trace_path {
    $_kerberos_env = "env KRB5_CLIENT_KTNAME=${kerberos_keytab_path} KRB5_TRACE=${kerberos_trace_path}"
  } elsif $kerberos_keytab_path {
    $_kerberos_env = "env KRB5_CLIENT_KTNAME=${kerberos_keytab_path}"
  } else {
    $_kerberos_env = undef
  }

  File {
    owner  => $script_owner,
    group  => $script_group,
  }

  file { "${deployment_configs_dir}/deployment_configs.py":
    ensure => file,
    mode   => $script_mode,
    source => 'puppet:///modules/mongodb_audit_tools/deployment_configs.py',
  }

  file { "${deployment_configs_dir}/deployment_configs.conf":
    ensure  => file,
    mode    => '0600',
    content => epp('mongodb_audit_tools/grabber.conf.epp', {
      audit_db_connection_string => $audit_db_connection_string,
      audit_db_ssl_ca_file_path  => $audit_db_ssl_pem_file_path,
      audit_db_ssl_pem_file_path => $audit_db_ssl_pem_file_path,
      audit_db_timeout           => $audit_db_timeout,
      enable_audit_db_ssl        => $enable_audit_db_ssl,
      enable_debugging           => $enable_debugging,
      enable_om_ssl              => $enable_om_ssl,
      excluded_root_keys         => $excluded_root_keys,
      om_api_connection_string   => $om_api_connection_string,
      om_api_ssl_ca_file_path    => $om_api_ssl_ca_file_path,
      om_api_ssl_pem_file_path   => $om_api_ssl_pem_file_path,
      om_api_timeout             => $om_api_timeout,
      om_token                   => $om_token,
      om_username                => $om_username,
      script_group               => $script_group,
      script_mode                => $script_mode,
      script_owner               => $script_owner,
    }),
    require => File["${deployment_configs_dir}/deployment_configs.py"],
  }

  # cron job here
  cron { 'deployment_config':
    ensure      => present,
    command     => "${python_path} ${deployment_configs_dir}/deployment_configs.py",
    environment => $_kerberos_env,
    hour        => $cron_hour,
    minute      => $cron_minute,
    monthday    => $cron_monthday,
  }
}

