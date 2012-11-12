maintainer       "Opscode, Inc."
maintainer_email "matt@opscode.com"
license          "Apache 2.0"
description      "The OpenStack Compute service Nova."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "5.0.0"

recipe		  "api-ec2", ""
recipe		  "api-metadata", ""
recipe		  "api-os-compute", ""
recipe		  "api-os-volume", ""
recipe		  "compute", ""
recipe		  "default", ""
recipe		  "libvirt", ""
recipe		  "network", ""
recipe		  "nova-common", ""
recipe		  "nova-scheduler-patch", ""
recipe		  "nova-setup", ""
recipe		  "scheduler", ""
recipe		  "vncproxy", ""
recipe		  "volume", ""

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

depends     "apt"
depends     "database"
depends     "osops-utils"
depends     "openstack-utils"
depends     "openstack-common"
depends     "mysql"
depends     "openssh"
depends     "rabbitmq"
depends     "selinux"
depends     "sysctl"
depends     "yum"
depends     "glance"
depends     "keystone"
