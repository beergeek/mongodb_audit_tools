require 'spec_helper'

describe 'mongodb_audit_tools::deployment_config_grabber' do
  context "Basics" do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
        operatingsystem: 'RedHat',
        osfamily:        'RedHat',
      }
    end
    let :params do
      {
        audit_db_connection_string: "mongodb://auditwriter%%40MONGODB.LOCAL@audit.mongodb.local:27017/?replicaSet=repl0&authSource=$external&authMechanism=GSSAPI",
        om_api_connection_string:    "mongodb://auditwriter%%40MONGODB.LOCAL@om.mongodb.local:27017/?replicaSet=repl0&authSource=$external&authMechanism=GSSAPI",
        deployment_configs_dir:     "/data/scripts",
      }
    end
    it { is_expected.to compile }
    it {
      is_expected.to contain_file('/data/scripts/deployment_configs.py').with(
        {
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0744'           }
      )
    }
    it {
      is_expected.to contain_file('/data/scripts/deployment_configs.conf').with(
        {
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0600',
        }
      ).that_requires('File[/data/scripts/deployment_configs.py]')
    }
    it {
      is_expected.to contain_file('/lib/systemd/system/mongodb_deployment_configs.service').with(
        {
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0644',
        }
      ).that_requires('File[/data/scripts/deployment_configs.py]')
    }
    it {
      is_expected.to contain_exec('restart_systemd_daemon_deployment_configs').with(
        'command'     => '/usr/bin/systemctl daemon-reload',
        'refreshonly' => true,
      ).that_subscribes_to('File[/lib/systemd/system/mongodb_deployment_configs.service]')
    }
    it {
      is_expected.to contain_service('mongodb_deployment_configs').with(
        {
          'ensure' => 'running',
          'enable' => true,
        }
      ).that_subscribes_to('File[/data/scripts/deployment_configs.conf]').that_subscribes_to('Exec[restart_systemd_daemon_deployment_configs]')
    }
  end
end