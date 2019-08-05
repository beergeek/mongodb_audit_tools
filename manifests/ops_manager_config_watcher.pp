# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include mongodb_audit_tools::ops_manager_config_watcher
class mongodb_audit_tools::ops_manager_config_watcher (
  Boolean                         $enable_audit_db_ssl,
  Boolean                         $enable_om_db_ssl,
  Boolean                         $enable_debugging,
  Boolean                         $enable_kerberos_debugging,
  Mongodb_audit_tools::MongoDBURL $audit_db_connection_string,
  Mongodb_audit_tools::MongoDBURL $om_db_connection_string,
  Stdlib::Absolutepath            $config_watcher_dir,
  Optional[Stdlib::Absolutepath]  $kerberos_file_path,
  Optional[Stdlib::Absolutepath]  $kerberos_trace_path,
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_ca_file_path,
  Optional[Stdlib::Absolutepath]  $om_db_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]  $om_db_ssl_ca_file_path,
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

  file { "${config_watcher_dir}/config_watcher.py":
    ensure => file,
    mode   => $script_mode,
    source => 'puppet:///modules/mongodb_audit_tools/config_watcher.py',
  }

  file { "${config_watcher_dir}/config_watcher.conf":
    ensure  => file,
    mode    => '0600',
    content => epp('mongodb_audit_tools/watcher.conf.epp', {
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
    require => File["${config_watcher_dir}/config_watcher.py"],
  }

  file { '/lib/systemd/system/mongodb_config_watcher.service':
    ensure  => file,
    mode    => '0644',
    content => epp('mongodb_audit_tools/watcher.service.epp', {
      enable_kerberos_debugging => $enable_kerberos_debugging,
      kerberos_file_path        => $kerberos_file_path,
      kerberos_trace_path       => $kerberos_trace_path,
      script_group              => $script_group,
      script_owner              => $script_owner,
      script_path               => "${config_watcher_dir}/config_watcher.py",
    }),
    require => File["${config_watcher_dir}/config_watcher.py"],
  }

  exec { 'restart_systemd_daemon_config_watcher':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/lib/systemd/system/mongodb_config_watcher.service'],
  }

  service { 'mongodb_config_watcher':
    ensure    => running,
    enable    => true,
    subscribe => [File["${config_watcher_dir}/config_watcher.conf"],Exec['restart_systemd_daemon_config_watcher']],
  }
}
