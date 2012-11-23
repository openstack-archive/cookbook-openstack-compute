#
# Cookbook Name:: nova
# Recipe:: db
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
  include ::Opscode::OpenSSL::Password
end

# TODO(jaypipes): This is retarded, but nothing runs without this. The
# database cookbook should handle this crap, but it doesn't. :(
include_recipe "mysql::client"
include_recipe "mysql::ruby"

# Allow for using a well known db password
if node["developer_mode"]
  node.set_unless["nova"]["db"]["password"] = "nova"
else
  node.set_unless["nova"]["db"]["password"] = secure_password
end

db_create_with_user("compute",
  node["nova"]["db"]["username"],
  node["nova"]["db"]["password"]
)
