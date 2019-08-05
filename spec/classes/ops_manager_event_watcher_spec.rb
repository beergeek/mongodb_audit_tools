require 'spec_helper'

describe 'mongodb_audit_tools::ops_manager_event_watcher' do
  on_supported_os.each do |os, os_facts|
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
          om_db_connection_string:    "mongodb://auditwriter%%40MONGODB.LOCAL@om.mongodb.local:27017/?replicaSet=repl0&authSource=$external&authMechanism=GSSAPI",
          event_watcher_dir:         "/data/scripts",
        }
      end

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('/data/scripts/event_watcher.py').with(
          {
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0744'           }
        )
      }

      it {
        is_expected.to contain_file('/data/scripts/event_watcher.conf').with(
          {
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0600',
          }
        ).that_requires('File[/data/scripts/event_watcher.py]')
      }

      it {
        is_expected.to contain_file('/lib/systemd/system/mongodb_event_watcher.service').with(
          {
            'ensure' => 'file',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644',
          }
        ).that_requires('File[/data/scripts/event_watcher.py]')
      }

      it {
        is_expected.to contain_exec('restart_systemd_daemon_event_watcher').with(
          'command'     => '/usr/bin/systemctl daemon-reload',
          'refreshonly' => true,
        ).that_subscribes_to('File[/lib/systemd/system/mongodb_event_watcher.service]')
      }

      it {
        is_expected.to contain_service('mongodb_event_watcher').with(
          {
            'ensure' => 'running',
            'enable' => true,
          }
        ).that_subscribes_to('File[/data/scripts/event_watcher.conf]').that_subscribes_to('Exec[restart_systemd_daemon_event_watcher]')
      }
    end
  end
end