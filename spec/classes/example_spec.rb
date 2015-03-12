require 'spec_helper'

describe 'uhosting' do
  context 'supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|
      describe "uhosting class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{
          :osfamily => osfamily,
        }}

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('uhosting::params') }
        it { is_expected.to contain_class('uhosting::install').that_comes_before('uhosting::config') }
        it { is_expected.to contain_class('uhosting::config') }
        it { is_expected.to contain_class('uhosting::service').that_subscribes_to('uhosting::config') }

        it { is_expected.to contain_service('uhosting') }
        it { is_expected.to contain_package('uhosting').with_ensure('present') }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'uhosting class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { is_expected.to contain_package('uhosting') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
