# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include mongodb_audit_tools::deployment_config_grabber
class mongodb_audit_tools::deployment_config_grabber (
  Boolean                         $enable_audit_db_ssl,
  Boolean                         $enable_debugging,
  Boolean                         $enable_kerberos_debugging,
  Mongodb_audit_tools::MongoDBURL $audit_db_connection_string,
  Mongodb_audit_tools::MongoDBURL $om_api_connection_string,
  Stdlib::Absolutepath            $deployment_configs_dir,
  Optional[Stdlib::Absolutepath]  $kerberos_file_path,
  Optional[Stdlib::Absolutepath]  $kerberos_trace_path,
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_ca_file_path,
  Optional[Stdlib::Absolutepath]  $om_api_ssl_pem_file_path,
  Optional[Stdlib::Absolutepath]  $om_api_ssl_ca_file_path,
  String[1]                       $script_owner,
  String[1]                       $script_group,
  String[1]                       $script_mode,
  Integer[1]                      $audit_db_timeout,
  Integer[1]                      $om_api_timeout,
  Optional[String[1]]             $change_stream_pipeline,
) {

  if $facts['os']['family'] != 'RedHat' {
    fail('This module is for RedHat family of Linux')
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
      change_stream_pipeline     => $change_stream_pipeline,
      enable_audit_db_ssl        => $enable_audit_db_ssl,
      enable_debugging           => $enable_debugging,
      om_api_connection_string   => $om_api_connection_string,
      om_api_ssl_ca_file_path    => $om_api_ssl_ca_file_path,
      om_api_ssl_pem_file_path   => $om_api_ssl_pem_file_path,
      om_api_timeout             => $om_api_timeout,
      script_owner               => $script_owner,
      script_group               => $script_group,
      script_mode                => $script_mode,
    }),
    require => File["${deployment_configs_dir}/deployment_configs.py"],
  }

  file { '/lib/systemd/system/mongodb_deployment_configs.service':
    ensure  => file,
    mode    => '0644',
    content => epp('mongodb_audit_tools/watcher.service.epp', {
      enable_kerberos_debugging => $enable_kerberos_debugging,
      kerberos_file_path        => $kerberos_file_path,
      kerberos_trace_path       => $kerberos_trace_path,
      script_group              => $script_group,
      script_owner              => $script_owner,
      script_path               => "${deployment_configs_dir}/deployment_configs.py",
    }),
    require => File["${deployment_configs_dir}/deployment_configs.py"],
  }

  exec { 'restart_systemd_daemon_deployment_configs':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/lib/systemd/system/mongodb_deployment_configs.service'],
  }

  service { 'mongodb_deployment_configs':
    ensure    => running,
    enable    => true,
    subscribe => [File["${deployment_configs_dir}/deployment_configs.conf"],Exec['restart_systemd_daemon_deployment_configs']],
  }
}

