require 'spec_helper'

describe 'mongodb_audit_tools::log_processor::install' do
  let :params do
    {
      log_processor_dir: '/data/scripts',
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
      is_expected.to contain_file('/data/scripts').with(
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
      )
    }

    it {
      is_expected.to contain_file('/data/scripts/log_processor.py').with(
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0744',
        'source' => 'puppet:///modules/mongodb_audit_tools/log_processor.py',
      )
    }
  end
end
