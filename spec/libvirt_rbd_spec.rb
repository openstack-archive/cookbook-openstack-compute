# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::libvirt_rbd' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS) do |n|
        n.set['openstack']['compute']['libvirt']['volume_backend'] = 'rbd'
      end
      @chef_run.converge 'openstack-compute::libvirt_rbd'
    end

    it 'includes the openstack-common::ceph_client recipe' do
      pending 'TODO: openstack-common needs that recipe first'
      expect(@chef_run).to include_recipe('openstack-common::ceph_client')
    end

    it 'installs rbd packages' do
      expect(@chef_run).to install_package 'ceph-common'
    end

    describe 'if there was no secret with this uuid defined' do
      before do
        @filename = '/tmp/ad3313264ea51d8c6a3d1c5b140b9883.xml'
      end

      it 'creates the temporary secret xml file' do
        expect(@chef_run).to create_template(@filename).with(
          owner: 'root',
          group: 'root',
          mode: '700'
        )
        # TODO(srenatus) cannot check for its contents because it's deleted at
        # the end of the (chefspec) chef run.
        # [/client\.cinder secret/,
        #  /00000000-0000-0000-0000-000000000000/].each do |content|
        #   expect(@chef_run).to render_file(@filename).with_content(content)
        # end
      end

      it 'defines the secret' do
        expect(@chef_run).to run_execute('virsh secret-define --file /tmp/ad3313264ea51d8c6a3d1c5b140b9883.xml')
      end

      it 'sets the secret value to the password' do
        expect(@chef_run).to run_execute("virsh secret-set-value --secret 00000000-0000-0000-0000-000000000000 'cinder-rbd-pass'")
      end

      it 'deletes the temporary secret xml file' do
        expect(@chef_run).to delete_file(@filename)
      end

    end

    # TODO(srenatus) negative tests?
    # describe 'if the secret was already defined' do
    #   before do
    #     stub_command('virsh secret-list | grep 00000000-0000-0000-0000-000000000000').and_return(true)
    #     stub_command('virsh secret-get-value 00000000-0000-0000-0000-000000000000 | grep \'cinder-rbd-pass\'').and_return(true)
    #   end
    # end
  end
end
