name             "nova"
maintainer       "Opscode, Inc."
maintainer_email "matt@opscode.com"
license          "Apache 2.0"
description      "The OpenStack Compute service Nova."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2012.2.1"

recipe "nova::api-ec2", "Installs AWS EC2 compatible API"
recipe "nova::api-metadata", "Installs the nova metadata package"
recipe "nova::api-os-compute", "Installs OS API"
recipe "nova::compute", "nova-compute service"
recipe "nova::db", "Configures database for use with nova"
recipe "nova::libvirt", "Installs libvirt, used by nova compute for management of the virtual machine environment"
recipe "nova::keystone_registration", "Registers the API and EC2 endpoints with Keystone"
recipe "nova::network", "Installs nova network service"
recipe "nova::nova-cert", "Installs nova-cert service"
recipe "nova::nova-common", "Builds the basic nova.conf config file with details of the rabbitmq, mysql, glance and keystone servers"
recipe "nova::nova-setup", "Sets up the nova database on the mysql server, including the initial schema and subsequent creation of the appropriate networks"
recipe "nova::scheduler", "Installs nova scheduler service"
recipe "nova::vncproxy", "Installs and configures the vncproxy service for console access to VMs"

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

depends "apache2"
depends "database"
depends "openstack-image"
depends "openstack-identity", ">= 2012.2.1"
depends "mysql"
depends "openstack-common", ">= 0.1.7"
depends "rabbitmq"
depends "selinux"
depends "sysctl"
depends "yum"
depends "python"
