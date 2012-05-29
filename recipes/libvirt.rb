#
# Cookbook Name:: openstack
# Recipe:: libvirt
#

platform_options = node["nova"]["platform"]

platform_options["libvirt_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

# oh fedora...
bash "create libvirtd group" do
  cwd "/tmp"
  user "root"
  code <<-EOH
      groupadd -f libvirtd
      usermod -G libvirtd nova
  EOH
  only_if { platform?(%w{fedora}) }
end

service "libvirt-bin" do
  service_name platform_options["libvirt_service"]
  supports :status => true, :restart => true
  action :enable
end

directory "/var/lib/nova/.ssh" do
    owner "nova"
    group "nova"
    mode "0700"
    action :create
end

template "/var/lib/nova/.ssh/id_dsa.pub" do
    # public key
    source "libvirtd-ssh-public-key.erb"
    owner "nova"
    group "nova"
    mode "0644"
    variables(
      :public_key => node["nova"]["libvirt"]["ssh"]["public_key"]
    )
end

template "/var/lib/nova/.ssh/id_dsa" do
    # private key
    source "libvirtd-ssh-private-key.erb"
    owner "nova"
    group "nova"
    mode "0600"
    variables(
      :private_key => node["nova"]["libvirt"]["ssh"]["private_key"]
    )
end

template "/var/lib/nova/.ssh/config" do
    # default config
    source "libvirtd-ssh-config"
    owner "nova"
    group "nova"
    mode "0644"
end

template "/var/lib/nova/.ssh/authorized_keys" do
    # copy of the public key
    source "libvirtd-ssh-public-key.erb"
    owner "nova"
    group "nova"
    mode "0600"
    variables(
      :public_key => node["nova"]["libvirt"]["ssh"]["public_key"]
    )
end

#
# TODO(breu): this section needs to be rewritten to support key privisioning
#
template "/etc/libvirt/libvirtd.conf" do
  source "libvirtd.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :auth_tcp => node["nova"]["libvirt"]["auth_tcp"]
  )
  notifies :restart, resources(:service => "libvirt-bin"), :immediately
end

template "/etc/default/libvirt-bin" do
  source "libvirt-bin.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "libvirt-bin"), :immediately
end
