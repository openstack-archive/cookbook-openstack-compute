#
# Cookbook Name:: openstack-compute
# Recipe:: ceilometer-db
#
# Copyright 2012, AT&T
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
#

# This recipe should be placed in the run_list of the node that
# runs the database server that houses the Nova main database

class ::Chef::Recipe
  include ::Openstack
end

# TODO(jaypipes): This is retarded, but nothing runs without this. The
# database cookbook should handle this crap, but it doesn't. :(
include_recipe "mysql::client"
include_recipe "mysql::ruby"

db_pass = db_password "ceilometer"

db_create_with_user("metering",
  node["openstack-compute"]["ceilometer"]["db"]["username"],
  db_pass
)
