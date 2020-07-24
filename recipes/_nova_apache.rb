# encoding: UTF-8
#
# Cookbook:: openstack-compute
# Recipe:: _nova_apache
#
# Copyright:: 2019-2020, Oregon State University
# Copyright:: 2020, x-ion GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'openstack-compute::nova-common'

# service['apache2'] is defined in the apache2_default_install resource
# but other resources are currently unable to reference it.  To work
# around this issue, define the following helper in your cookbook:
service 'apache2' do
  extend Apache2::Cookbook::Helpers
  service_name lazy { apache_platform_service_name }
  supports restart: true, status: true, reload: true
  action :nothing
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end
