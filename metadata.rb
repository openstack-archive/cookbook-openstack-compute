maintainer       "Opscode, Inc."
maintainer_email "matt@opscode.com"
license          "Apache 2.0"
description      "The OpenStack Compute service Nova."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2012.2.0"
name             "nova"

recipe "nova::api-ec2", "Installs AWS EC2 compatible API and configures the service and endpoints in keystone"
recipe "nova::api-metadata", "Installs the nova metadata package"
recipe "nova::api-os-compute", "Installs OS API and configures the service and endpoints in keystone"
recipe "nova::api-os-volume", ""
recipe "nova::compute", "nova-compute service"
recipe "nova::api-os-volume", "Installs the OpenStack volume service API"
recipe "nova::db", "Configures database for use with nova"
recipe "nova::libvirt", "Installs libvirt, used by nova compute for management of the virtual machine environment"
recipe "nova::network", "Installs nova network service"
recipe "nova::nova-common", "Builds the basic nova.conf config file with details of the rabbitmq, mysql, glance and keystone servers"
recipe "nova::nova-setup", "Sets up the nova database on the mysql server, including the initial schema and subsequent creation of the appropriate networks"
recipe "nova::scheduler", "Installs nova scheduler service"
recipe "nova::vncproxy", "Installs and configures the vncproxy service for console access to VMs"
recipe "nova::volume", "Installs nova volume service and configures the service and endpoints in keystone"

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

depends "database"
depends "glance"
depends "keystone"
depends "mysql"
depends "openssl"
depends "openstack-utils"
depends "openstack-common"
depends "osops-utils"
depends "rabbitmq"
depends "selinux"
depends "sysctl"
depends "yum"
