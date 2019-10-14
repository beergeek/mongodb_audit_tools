require 'spec_helper'

describe 'mongodb_audit_tools::log_processor' do
  let(:title) { 'logger' }
  let :params do
    {
      log_processor_dir:         '/data/scripts',
      audit_db_connection_string: 'mongodb://auditwriter%%40MONGODB.LOCAL@audit.mongodb.local:27017/?replicaSet=repl0&authSource=$external&authMechanism=GSSAPI',
      om_token: 'trvbunim-45678-rtyvubghinjm',
      om_username: 'loudSam'
    }
  end

  context "Basics" do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
        operatingsystem: 'RedHat',
        osfamily:        'RedHat',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/data/scripts/logger_log_processor.py').with(
        {
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0744'           }
      )
    }

    it {
      is_expected.to contain_file('/data/scripts/logger_log_processor.conf').with(
        {
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0600',
        }
      ).that_requires('File[/data/scripts/logger_log_processor.py]')
    }

    it {
      is_expected.to contain_file('/lib/systemd/system/mongodb_log_processor_logger.service').with(
        {
          'ensure' => 'file',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0644',
        }
      ).that_requires('File[/data/scripts/logger_log_processor.py]')
    }

    it {
      is_expected.to contain_exec('restart_systemd_daemon_log_processor_logger').with(
        'command'     => '/usr/bin/systemctl daemon-reload',
        'refreshonly' => true,
      ).that_subscribes_to('File[/lib/systemd/system/mongodb_log_processor_logger.service]')
    }

    it {
      is_expected.to contain_service('mongodb_log_processor_logger').with(
        {
          'ensure' => 'running',
          'enable' => true,
        }
      ).that_subscribes_to('File[/data/scripts/logger_log_processor.conf]').that_subscribes_to('Exec[restart_systemd_daemon_log_processor_logger]')
    }
  end
end
