Description
===========

This cookbook installs the OpenStack Compute service **Nova** as part of the OpenStack **Essex** reference deployment Chef for OpenStack. The http://github.com/opscode/openstack-chef-repo contains documentation for using this cookbook in the context of a full OpenStack deployment. Nova is installed from packages.

http://nova.openstack.org

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

* Ubuntu-12.04
* Fedora-17

Cookbooks
---------

The following cookbooks are dependencies:

* apt
* database
* glance
* keystone
* mysql
* openssh
* osops-utils
* rabbitmq
* selinux (Fedora)
* sysctl

Recipes
=======

api-ec2
----
-Includes recipe `nova-common`
-Installs AWS EC2 compatible API and configures the service and endpoints in keystone

api-metadata
----
-Includes recipe `nova-common`
-Installs the nova metadata package

api-os-compute
----
-Includes recipe `nova-common`
-Installs OS API and configures the service and endpoints in keystone

api-os-volume
----
-Includes recipe `nova-common`
-Installs the OpenStack volume service API

apt
----
-Performs an apt-get update

compute
----
-Includes recipes `nova-common`, `api-metadata`, `network`
-Installs nova-compute service

libvirt
----
-Installs libvirt, used by nova compute for management of the virtual machine environment

network
----
-Includes recipe `nova-common`
-Installs nova network service

nova-common
----
-May include recipe `selinux` (Fedora)
-Builds the basic nova.conf config file with details of the rabbitmq, mysql, glance and keystone servers
-Builds a openrc file for root with appropriate environment variables to interact with the nova client CLI

nova-setup
----
-Includes recipes `nova-common`, `mysql:client`
-Sets up the nova database on the mysql server, including the initial schema and subsequent creation of the appropriate networks

scheduler
----
-Includes recipe `nova-common`
-Installs nova scheduler service

vncproxy
----
-Includes recipe `nova-common`
-Installs and configures the vncproxy service for console access to VMs

volume
----
-Includes recipes `nova-common`, `api-os-volume`
-Installs nova volume service and configures the service and endpoints in keystone

nova-scheduler-patch
----
-Includes recipe osops-utils
-Patches nova-scheduler based on installed package version


Attributes
==========

* `nova["patch_files_on_disk"] - Boolean for patching files on disk
* `nova["db"]["name"]` - Name of nova database
* `nova["db"]["username"]` - Username for nova database access
* `nova["db"]["password"]` - Password for nova database access
NOTE: db password is no longer set statically in the attributes file, but securely/randomly in the nova-common recipe

* `nova["service_tenant_name"]` - Tenant name used by nova when interacting with keystone
* `nova["service_user"]` - User name used by nova when interacting with keystone
* `nova["service_pass"]` - User password used by nova when interacting with keystone
NOTE: service password is no longer set statically in the attributes file, but securely/randomly in the *api recipes
* `nova["service_role"]` - User role used by nova when interacting with keystone

* `nova["compute"]["api"]["protocol"]` - Protocol used for the OS API
* `nova["compute"]["api"]["port"]` - Port on which OS API runs
* `nova["compute"]["api"]["version"]` - Version of the OS API used

* `nova["compute"]["adminURL"]` - URL used to access the OS API for admin functions
* `nova["compute"]["internalURL"]` - URL used to access the OS API for user functions from an internal network
* `nova["compute"]["publicURL"]` - URL used to access the OS API for user functions from an external network

* `nova["config"]["availability_zone"]` - Nova availability zone.  Usually set at the node level to place a compute node in another az
* `nova["config"]["default_schedule_zone"]` - The availability zone to schedule instances in when no az is specified in the request
* `nova["config"]["force_raw_images"]` - Convert all images used as backing files for instances to raw (we default to false)
* `nova["config"]["allow_same_net_traffic"]` - Disable security groups for internal networks (we default to true)
* `nova["config"]["osapi_max_limit"]` - The maximum number of items returned in a single response from a collection resource (default is 1000)
* `nova["config"]["cpu_allocation_ratio"]` - Virtual CPU to Physical CPU allocation ratio (default 16.0)
* `nova["config"]["ram_allocation_ratio"]` - Virtual RAM to Physical RAM allocation ratio (default 1.5)
* `nova["config"]["snapshot_image_format"]` - Snapshot image format (valid options are : raw, qcow2, vmdk, vdi [we default to qcow2]).
* `nova["config"]["start_guests_on_host_boot"]` - Whether to restart guests when the host reboots
* `nova["config"]["resume_guests_state_on_host_boot"]` - Whether to start guests that were running before the host rebooted

* `nova["ec2"]["api"]["protocol"]` - Protocol used for the AWS EC2 compatible API
* `nova["ec2"]["api"]["port"]` - Port on which AWS EC2 compatible API runs
* `nova["ec2"]["api"]["admin_path"]` - Path for admin functions in the AWS EC2 compatible API
* `nova["ec2"]["api"]["cloud_path"]` - Path for service functions in the AWS EC2 compatible API

* `nova["ec2"]["adminURL"]` - URL used to access the AWS EC2 compatible API for admin functions
* `nova["ec2"]["internalURL"]` - URL used to access the AWS EC2 compatible API for user functions from an internal network
* `nova["ec2"]["publicURL"]` - URL used to access the AWS EC2 compatible API for user functions from an external network

* `nova["xvpvnc"]["proxy_bind_host"]` - IP address which the xvpvncproxy binds to
* `nova["xvpvnc"]["proxy_bind_port"]` - Port on which the xvpvncproxy runs
* `nova["xvpvnc"]["ip_address"]` - IP address for accessing the xvpvncproxy service
* `nova["xvpvnc"]["proxy_base_url"]` - Base URL returned for xvpvncproxy requests

* `nova["novnc"]["proxy_bind_port"]` - Port on which the novncproxy runs
* `nova["novnc"]["proxy_base_url"]` - Base URL returned for novncproxy requests

* `nova["volume"]["api_port"]` - Port on which nova volumes API runs
* `nova["volume"]["ipaddress"]` - IP address where nova volumes API runs
* `nova["volume"]["adminURL"]` - URL used to access the nova volumes API for admin functions
* `nova["volume"]["internalURL"]` - URL used to access the nova volumes API for user functions from an internal network
* `nova["volume"]["publicURL"]` - URL used to access the nova volumes API for user functions from an external network

* `nova["network"]["public"]["label"]` - Network label to be assigned to the public network on creation
* `nova["network"]["public"]["ipv4_cidr"]` - Network to be created (in CIDR notation, e.g., 192.168.100.0/24)
* `nova["network"]["public"]["num_networks"]` - Number of networks to be created
* `nova["network"]["public"]["network_size"]` - Number of IP addresses to be used in this network
* `nova["network"]["public"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br100)
* `nova["network"]["public"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth2)
* `nova["network"]["public"]["dns1"]` - DNS server 1
* `nova["network"]["public"]["dns2"]` - DNS server 2

* `nova["network"]["private"]["label"]` - Network label to be assigned to the private network on creation
* `nova["network"]["private"]["ipv4_cidr"]` - Network to be created (in CIDR notation e.g., 192.168.200.0/24)
* `nova["network"]["private"]["num_networks"]` - Number of networks to be created
* `nova["network"]["private"]["network_size"]` - Number of IP addresses to be used in this network
* `nova["network"]["private"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br200)
* `nova["network"]["private"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth3)

* `nova["libvirt"]["virt_type"]` - What hypervisor software layer to use with libvirt (e.g., kvm, qemu)

* `nova["libvirt"]["vncserver_listen"]` - IP address on the hypervisor that libvirt listens for VNC requests on
* `nova["libvirt"]["vncserver_proxyclient_address"]` - IP address on the hypervisor that libvirt exposes for VNC requests on (should be the same as vncserver_listen)

* `nova["libvirt"]["auth_tcp"]` - Type of authentication your libvirt layer requires
* `nova["libvirt"]["ssh"]["private_key"]` - Private key to use if using SSH authentication to your libvirt layer
* `nova["libvirt"]["ssh"]["public_key"]` - Public key to use if using SSH authentication to your libvirt layer

* `nova["scheduler"]["scheduler_driver"]` - the scheduler driver to use
NOTE: The filter scheduler currently does not work with ec2.
* `nova["scheduler"]["default_filters"]` - a list of filters enabled for schedulers that support them.

* `nova["syslog"]["use"]` - Should nova log to syslog?
* `nova["syslog"]["facility"]` - Which facility nova should use when logging in python style (for example, LOG_LOCAL1)
* `nova["syslog"]["config_facility"]` - Which facility nova should use when logging in rsyslog style (for example, local1)

Templates
=====
* `api-paste.ini.erb` - Paste config for nova API middleware
* `libvirt-bin.erb` - Initscript for starting libvirtd
* `libvirtd-ssh-config` - Config file for libvirt SSH auth
* `libvirtd-ssh-private-key.erb` - Private SSH key for libvirt SSH
* `libvirtd-ssh-public-key.erb` - Public SSH key for libvirt SSH auth
* `libvirtd.conf.erb` - Libvirt config file
* `local_settings.py.erb` - Dashboard (horizon) config file
* `nova.conf.erb` - Basic nova.conf file
* `openrc.erb` - Contains environment variable settings to enable easy use of the nova client
* `patches/` - misc. patches for nova


License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)
Author:: Ron Pedde (<ron.pedde@rackspace.com>)
Author:: Joseph Breu (<joseph.breu@rackspace.com>)
Author:: William Kelly (<william.kelly@rackspace.com>)
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)
Author:: Matt Ray (<matt@opscode.com>)

Copyright 2012, Rackspace US, Inc.
Copyright 2012, Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
