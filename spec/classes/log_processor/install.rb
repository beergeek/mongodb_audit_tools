require 'spec_helper'

describe 'mongodb_audit_tools::log_processor::install' do
  let :params do
    {
      log_processor_dir:          '/data/scripts',
      audit_db_connection_string: 'mongodb://auditwriter%%40MONGODB.LOCAL@audit.mongodb.local:27017/?replicaSet=repl0&authSource=$external&authMechanism=GSSAPI',
      om_token:                   'trvbunim-45678-rtyvubghinjm',
      om_username:                'loudSam',
    }
  end

  context 'Basics' do
    let :facts do
      {
        os:              { 'family' => 'RedHat', 'release' => { 'major' => '7' } },
        operatingsystem: 'RedHat',
        osfamily:        'RedHat',
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/data/scripts/log_processor.py').with(
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0744',
      )
    }
  end
end
