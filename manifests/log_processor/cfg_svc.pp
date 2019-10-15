# @summary Log processor.
#
# A description of what this defined type does
#
# @example
#   mongodb_audit_tools::log_processor { 'namevar': }
define mongodb_audit_tools::log_processor::cfg_svc (
  Mongodb_audit_tools::MongoDBURL $audit_db_connection_string,
  Stdlib::Absolutepath            $log_processor_dir,
  String[1]                       $om_token,
  String[1]                       $om_username,
  Stdlib::Absolutepath            $config_file_path             = "${log_processor_dir}/${title}.conf",
  Stdlib::Absolutepath            $log_file_path                = "${log_processor_dir}/${title}.log",

  # Lookups from Hiera
  Boolean                         $enable_audit_db_ssl          = lookup('mongodb_audit_tools::log_processor::enable_audit_db_ssl'),
  Boolean                         $enable_debugging             = lookup('mongodb_audit_tools::log_processor::enable_debugging'),
  Boolean                         $enable_kerberos_debugging    = lookup('mongodb_audit_tools::log_processor::enable_kerberos_debugging'),
  Optional[Array[String[1]]]      $elevated_ops_events          = lookup('mongodb_audit_tools::log_processor::elevated_ops_events'),
  Optional[Array[String[1]]]      $elevated_app_events          = lookup('mongodb_audit_tools::log_processor::elevated_app_events'),
  Optional[Array[String[1]]]      $elevated_config_events       = lookup('mongodb_audit_tools::log_processor::elevated_config_events'),
  Optional[Stdlib::Absolutepath]  $kerberos_keytab_path         = lookup('mongodb_audit_tools::log_processor::kerberos_keytab_path'),
  Optional[Stdlib::Absolutepath]  $kerberos_trace_path          = lookup('mongodb_audit_tools::log_processor::kerberos_trace_path'),
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_pem_file_path   = lookup('mongodb_audit_tools::log_processor::audit_db_ssl_pem_file_path'),
  Optional[Stdlib::Absolutepath]  $audit_db_ssl_ca_file_path    = lookup('mongodb_audit_tools::log_processor::audit_db_ssl_ca_file_path'),
  Optional[Stdlib::Absolutepath]  $audit_log                    = lookup('mongodb_audit_tools::log_processor::audit_log'),
  Optional[Stdlib::Absolutepath]  $python_path                  = lookup('mongodb_audit_tools::log_processor::python_path'),
  String[1]                       $script_owner                 = lookup('mongodb_audit_tools::log_processor::script_owner'),
  String[1]                       $script_group                 = lookup('mongodb_audit_tools::log_processor::script_group'),
  Integer[1]                      $audit_db_timeout             = lookup('mongodb_audit_tools::log_processor::audit_db_timeout'),
) {

  if $facts['os']['family'] != 'RedHat' {
    fail('This module is for RedHat family of Linux')
  }

  require mongodb_audit_tools::log_processor::install

  File {
    owner  => $script_owner,
    group  => $script_group,
  }

  file { "log_processor - ${title} config":
    ensure  => file,
    path    => $config_file_path,
    mode    => '0600',
    content => epp('mongodb_audit_tools/log_processor.conf.epp', {
      audit_db_connection_string => $audit_db_connection_string,
      audit_db_ssl_ca_file_path  => $audit_db_ssl_pem_file_path,
      audit_db_ssl_pem_file_path => $audit_db_ssl_pem_file_path,
      audit_db_timeout           => $audit_db_timeout,
      audit_log                  => $audit_log,
      elevated_ops_events        => join($elevated_ops_events, ','),
      elevated_app_events        => join($elevated_app_events, ','),
      elevated_config_events     => join($elevated_config_events, ','),
      enable_audit_db_ssl        => $enable_audit_db_ssl,
      enable_debugging           => $enable_debugging,
      script_owner               => $script_owner,
      script_group               => $script_group,
      script_mode                => $script_mode,
    }),
    require => Class['mongodb_audit_tools::log_processor::install'],
  }

  file { "/lib/systemd/system/mongodb_log_processor_${title}.service":
    ensure  => file,
    mode    => '0644',
    content => epp('mongodb_audit_tools/service.epp', {
      config_file_path          => $config_file_path,
      enable_kerberos_debugging => $enable_kerberos_debugging,
      kerberos_keytab_path      => $kerberos_keytab_path,
      kerberos_trace_path       => $kerberos_trace_path,
      log_file_path             => $log_file_path,
      python_path               => $python_path,
      script_group              => $script_group,
      script_owner              => $script_owner,
      script_path               => "${log_processor_dir}/${title}_log_processor.py",
    }),
    require => File["log_processor - ${title} config"],
  }

  exec { "restart_systemd_daemon_log_processor_${title}":
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File["/lib/systemd/system/mongodb_log_processor_${title}.service"],
  }

  service { "mongodb_log_processor_${title}":
    ensure    => running,
    enable    => true,
    subscribe => [File["log_processor - ${title} config"],Exec["restart_systemd_daemon_log_processor_${title}"]],
  }
}
