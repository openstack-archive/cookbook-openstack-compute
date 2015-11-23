# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::docker-setup' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    %w(python-devel git gcc).each do |pkg|
      it do
        expect(chef_run).to upgrade_package pkg
      end
    end
  end
end
