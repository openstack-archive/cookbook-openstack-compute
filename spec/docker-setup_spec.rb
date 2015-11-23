# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::docker-setup' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    it 'runs a run python pip setuptools' do
      expect(chef_run).to upgrade_python_pip('setuptools')
    end

    it 'runs a run python pip pbr' do
      expect(chef_run).to upgrade_python_pip('pbr')
    end

    it 'upgrades git package' do
      expect(chef_run).to upgrade_package 'git'
    end

    it 'upgrades gcc package' do
      expect(chef_run).to upgrade_package 'gcc'
    end

    it 'upgrades python-dev package' do
      expect(chef_run).to upgrade_package 'python-dev'
    end

    git_local_dir = Chef::Config[:file_cache_path] + '/nova-docker'

    it 'syncs a git with nova docker git repo' do
      expect(chef_run).to sync_git(git_local_dir).with(repository: 'https://github.com/stackforge/nova-docker')
    end

    it 'runs a bash block install nova docker driver' do
      expect(chef_run).to run_bash('install nova docker driver')
    end
  end
end
