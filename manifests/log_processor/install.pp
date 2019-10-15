# @summary Log processor.
#
# A description of what this defined type does
#
# @example
#   mongodb_audit_tools::log_processor { 'namevar': }
class mongodb_audit_tools::log_processor::install (
  Stdlib::Absolutepath $log_processor_dir,
  String[1]            $script_owner,
  String[1]            $script_group,
  String[1]            $script_mode,
) {

  if $facts['os']['family'] != 'RedHat' {
    fail('This module is for RedHat family of Linux')
  }

  File {
    owner  => $script_owner,
    group  => $script_group,
  }

  file { $log_processor_dir:
    ensure => directory,
    mode   => '0755',
  }

  file { "${log_processor_dir}/log_processor.py":
    ensure => file,
    mode   => $script_mode,
    source => 'puppet:///modules/mongodb_audit_tools/log_processor.py',
  }
}
