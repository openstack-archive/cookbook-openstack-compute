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
recipe		  "nova-db-monitoring", ""
recipe		  "nova-rsyslog", ""
recipe		  "nova-scheduler-patch", ""
recipe		  "nova-setup", ""
recipe		  "scheduler", ""
recipe		  "vncproxy", ""
recipe		  "volume", ""

%w{ ubuntu fedora }.each do |os|
  supports os
end

%w{ apt database glance keystone mysql openssh rabbitmq osops-utils sysctl }.each do |dep|
  depends dep
end
