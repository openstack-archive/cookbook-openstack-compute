#
# Cookbook Name:: nova
# Recipe:: default
#
# Copyright 2009, Rackspace Hosting, Inc.
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

if node["nova"]["syslog"]["use"] == true
    template "/etc/rsyslog.d/21-nova.conf" do
        source "21-nova.conf.erb"
        owner "root"
        group "root"
        mode "0644"
        variables(
            "use_syslog" => node["nova"]["syslog"]["use"],
            "log_facility" => node["nova"]["syslog"]["facility"]
        )
    end
end
