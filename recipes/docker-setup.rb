# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: docker-setup
#
# Copyright 2015 IBM Corp.
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.

#   Make sure that docker runtime is installed as a prerequsite

include_recipe 'python::pip'

# set nova docker driver as the compute driver
node.set['openstack']['compute']['driver'] = node['openstack']['compute']['docker']['driver']
docker_service_sock = node['openstack']['compute']['docker']['service_sock']
docker_service_sock_mode = node['openstack']['compute']['docker']['service_sock_mode']
platform_options = node['openstack']['compute']['platform']
pip_build_pkgs = node['openstack']['compute']['docker']['pip_build_pkgs']

# upgrade the required packages (some packages will be removed once RPM based nova-docker installation is introduced)
platform_options['docker_build_pkgs'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']

    action :upgrade
  end
end

# This will be removed once RPM based installation of nova-docker driver is available
pip_build_pkgs.each do |pip_pkg|
  python_pip pip_pkg do
    action :upgrade
  end
end

# Below code downloads docker driver from configured git repo and branch
github_repository = node['openstack']['compute']['docker']['github']['repository']
github_branch =   node['openstack']['compute']['docker']['github']['branch']
git_download_directory  = "#{Chef::Config['file_cache_path']}/nova-docker"

git git_download_directory do
  repository github_repository
  revision github_branch
  action :sync
end

# Configure nova docker driver
bash 'install nova docker driver' do
  cwd git_download_directory
  code <<-EOH
    chmod #{docker_service_sock_mode} #{docker_service_sock}
    python ./setup.py build
    python ./setup.py install
  EOH
end
