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
        om_token: 'trvbunim-45678-rtyvubghinjm',
        om_username: 'loudSam'
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
      is_expected.to contain_cron('deployment_config').with(
          'ensure'      => 'present',
          'command'     => '/bin/python3 /data/scripts/deployment_configs.py',
          'hour'        => 1,
          'minute'      => '*',
          'monthday'    => '*',
      ).without_environment
    }
  end

  context "With Kerberos" do
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
        kerberos_keytab_path: '/data/pki/audit.keytab',
        kerberos_trace_path: '/data/logs/krb5.log',
        om_token: 'trvbunim-45678-rtyvubghinjm',
        om_username: 'loudSam'
      }
    end

    it {
      is_expected.to contain_cron('deployment_config').with(
          'ensure'      => 'present',
          'command'     => '/bin/python3 /data/scripts/deployment_configs.py',
          'environment' => 'env KRB5_CLIENT_KTNAME=/data/pki/audit.keytab KRB5_TRACE=/data/logs/krb5.log',
          'hour'        => 1,
          'minute'      => '*',
          'monthday'    => '*',
      )
    }
  end
end