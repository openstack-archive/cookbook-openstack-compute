# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  describe 'redhat' do
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'runs epel recipe' do
      expect(chef_run).to include_recipe 'yum-epel'
    end

    it 'installs nova common packages' do
      expect(chef_run).to upgrade_package 'openstack-nova-common'
    end

    it 'installs mysql python packages by default' do
      expect(chef_run).to install_package 'MySQL-python'
    end

    it 'installs db2 python packages if explicitly told' do
      node.set['openstack']['db']['compute']['service_type'] = 'db2'
      ['python-ibm-db', 'python-ibm-db-sa'].each do |pkg|
        expect(chef_run).to install_package pkg
      end
    end

    it 'installs memcache python packages' do
      expect(chef_run).to install_package 'python-memcached'
    end

    describe 'nova.conf' do
      let(:file) { chef_run.template('/etc/nova/nova.conf') }

      [/^ec2_private_dns_show_ip=True$/, /^force_dhcp_release=false$/].each do |content|
        it "has a #{content.source[1...-1]} line" do
          expect(chef_run).to render_file(file.name).with_content(content)
        end
      end
    end
  end
end
