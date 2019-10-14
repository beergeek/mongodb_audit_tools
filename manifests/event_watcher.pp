# @summary A short summary of the purpose of this class
#
# Manages the installation, configuration and service of the event_watcher Python script
#
# @param enable_audit_db_ssl Boolean to determine if SSL/TLS is enabled for the Audit DB connection.
# @param enable_om_ssl Boolean to determine if SSL/TLS is enabled for the OPs Manager connection.
# @param enable_debugging Boolean to determine if debugging is enabled in the event_watcher config file.
# @param enable_kerberos_debugging Boolean to determine if the environmental variable for Kerberos debugging is
#   enabled in the sciprt's service file.
# @param audit_db_connection_string The MongoDB connection string for the Audit DB.
# @param om_api_connection_string The connection string for Ops Manager, include the user and token.
# @param event_watcher_dir The absolute path to create the script and config files.
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
#
# @example
#   class { 'mongodb_audit_tools::ops_manager_event_watcher':
#     audit_db_connection_string => 'mongodb://audit%40MONGODB.LOCAL@auditor.mongodb.local:27017/?replicaSet=repl00&authSource=$external&authMechanism=GSSAPI',
#     deployment_configs_dir     => '/data/scripts',
#     om_api_connection_string   => 'https://mongod0.mongodb.local:8443',
#     om_username                => 'loudSam',
#     om_token                   => '8ce50f02-4292-460e-82a5-236a074218aa',
#   }
#
class mongodb_audit_tools::event_watcher (
  Boolean                         $enable_audit_db_ssl,
  Boolean                         $enable_om_db_ssl,
  Boolean                         $enable_debugging,
  Boolean                         $enable_kerberos_debugging,
  Mongodb_audit_tools::MongoDBURL $audit_db_connection_string,
  Mongodb_audit_tools::MongoDBURL $om_db_connection_string,
  Stdlib::Absolutepath            $event_watcher_dir,
  Optional[Stdlib::Absolutepath]  $kerberos_keytab_path,
  Optional[Stdlib::Absolutepath]  $kerberos_trace_path,
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_ca_file_path,
  Optional[Stdlib::Absolutepath]  $om_db_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]  $om_db_ssl_ca_file_path,
  Optional[Stdlib::Absolutepath]  $python_path,
  String[1]                       $om_token,
  String[1]                       $om_username,
  String[1]                       $script_owner,
  String[1]                       $script_group,
  String[1]                       $script_mode,
  Integer[1]                      $audit_db_timeout,
  Integer[1]                      $om_db_timeout,
  Optional[String[1]]             $change_stream_pipeline,
) {

  if $facts['os']['family'] != 'RedHat' {
    fail('This module is for RedHat family of Linux')
  }

  File {
    owner  => $script_owner,
    group  => $script_group,
  }

  file { "${event_watcher_dir}/event_watcher.py":
    ensure => file,
    mode   => $script_mode,
    source => 'puppet:///modules/mongodb_audit_tools/event_watcher.py',
  }

  file { "${event_watcher_dir}/event_watcher.conf":
    ensure  => file,
    mode    => '0600',
    content => epp('mongodb_audit_tools/event_watcher.conf.epp', {
      audit_db_connection_string => $audit_db_connection_string,
      audit_db_ssl_ca_file_path  => $audit_db_ssl_pem_file_path,
      audit_db_ssl_pem_file_path => $audit_db_ssl_pem_file_path,
      audit_db_timeout           => $audit_db_timeout,
      change_stream_pipeline     => $change_stream_pipeline,
      enable_audit_db_ssl        => $enable_audit_db_ssl,
      enable_debugging           => $enable_debugging,
      enable_om_db_ssl           => $enable_om_db_ssl,
      om_db_connection_string    => $om_db_connection_string,
      om_db_ssl_ca_file_path     => $om_db_ssl_ca_file_path,
      om_db_ssl_pem_file_path    => $om_db_ssl_pem_file_path,
      om_db_timeout              => $om_db_timeout,
      script_owner               => $script_owner,
      script_group               => $script_group,
      script_mode                => $script_mode,
    }),
    require => File["${event_watcher_dir}/event_watcher.py"],
  }

  file { '/lib/systemd/system/mongodb_event_watcher.service':
    ensure  => file,
    mode    => '0644',
    content => epp('mongodb_audit_tools/event_watcher.service.epp', {
      enable_kerberos_debugging => $enable_kerberos_debugging,
      kerberos_keytab_path      => $kerberos_keytab_path,
      kerberos_trace_path       => $kerberos_trace_path,
      script_group              => $script_group,
      script_owner              => $script_owner,
      script_path               => "${event_watcher_dir}/event_watcher.py",
      python_path               => $python_path,
    }),
    require => File["${event_watcher_dir}/event_watcher.py"],
  }

  exec { 'restart_systemd_daemon_event_watcher':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/lib/systemd/system/mongodb_event_watcher.service'],
  }

  service { 'mongodb_event_watcher':
    ensure    => running,
    enable    => true,
    subscribe => [File["${event_watcher_dir}/event_watcher.conf"],Exec['restart_systemd_daemon_event_watcher']],
  }
}
