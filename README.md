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

* `default["nova"]["patch_files_on_disk"]` - Boolean for patching files on disk
* `default["nova"]["db"]["name"]` - Name of nova database
* `default["nova"]["db"]["username"]` - Username for nova database access
* `default["nova"]["db"]["password"]` - Password for nova database access
NOTE: db password is no longer set statically in the attributes file, but securely/randomly in the nova-common recipe

* `default["nova"]["service_tenant_name"]` - Tenant name used by nova when interacting with keystone
* `default["nova"]["service_user"]` - User name used by nova when interacting with keystone
* `default["nova"]["service_pass"]` - User password used by nova when interacting with keystone
NOTE: service password is no longer set statically in the attributes file, but securely/randomly in the `*api` recipes
* `default["nova"]["service_role"]` - User role used by nova when interacting with keystone

* `default["nova"]["compute"]["api"]["protocol"]` - Protocol used for the OS API
* `default["nova"]["compute"]["api"]["port"]` - Port on which OS API runs
* `default["nova"]["compute"]["api"]["version"]` - Version of the OS API used

* `default["nova"]["compute"]["adminURL"]` - URL used to access the OS API for admin functions
* `default["nova"]["compute"]["internalURL"]` - URL used to access the OS API for user functions from an internal network
* `default["nova"]["compute"]["publicURL"]` - URL used to access the OS API for user functions from an external network

* `default["nova"]["config"]["availability_zone"]` - Nova availability zone.  Usually set at the node level to place a compute node in another az
* `default["nova"]["config"]["default_schedule_zone"]` - The availability zone to schedule instances in when no az is specified in the request
* `default["nova"]["config"]["force_raw_images"]` - Convert all images used as backing files for instances to raw (we default to false)
* `default["nova"]["config"]["allow_same_net_traffic"]` - Disable security groups for internal networks (we default to true)
* `default["nova"]["config"]["osapi_max_limit"]` - The maximum number of items returned in a single response from a collection resource (default is 1000)
* `default["nova"]["config"]["cpu_allocation_ratio"]` - Virtual CPU to Physical CPU allocation ratio (default 16.0)
* `default["nova"]["config"]["ram_allocation_ratio"]` - Virtual RAM to Physical RAM allocation ratio (default 1.5)
* `default["nova"]["config"]["snapshot_image_format"]` - Snapshot image format (valid options are : raw, qcow2, vmdk, vdi [we default to qcow2]).
* `default["nova"]["config"]["start_guests_on_host_boot"]` - Whether to restart guests when the host reboots
* `default["nova"]["config"]["resume_guests_state_on_host_boot"]` - Whether to start guests that were running before the host rebooted

Service Endpoint Attributes
---------------------------

Each Nova service endpoint is listed as a Hash in the `default["nova"]["services"]` Hash. Each
Hash that describes a service endpoint should contain **either** a `uri` key **OR** contain
keys for `scheme`, `port`, `path`, and `network`, where `network` is something like "public" or "private" and
refers to a Hash of network information that is used by the `osops-utils::ip_location` library to determine
an IP address in a named network.

Here are the defaults:

* `default["nova"]["services"]["api"]["scheme"]` = "http" - Protocol used for the OpenStack Compute API endpoint
* `default["nova"]["services"]["api"]["port"]` = "8774" - Port on which the OpenStack Compute API runs
* `default["nova"]["services"]["api"]["network"]` = "public" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["api"]["path"]` = "/v2/`%(tenant_id)s`" - The path after host to this endpoint

* `default["nova"]["services"]["ec2-public"]["scheme"]` = "http" - Protocol used for the AWS EC2 compatible API endpoint
* `default["nova"]["services"]["ec2-public"]["port"]` = "8773" - Port on which AWS EC2 compatible API runs
* `default["nova"]["services"]["ec2-public"]["network"]` = "public" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["ec2-public"]["path"]` = "/services/Cloud" - The path after host to this endpoint

* `default["nova"]["services"]["ec2-admin"]["scheme"]` = "http" - Protocol used for the AWS EC2 compatible Admin API endpoint
* `default["nova"]["services"]["ec2-admin"]["port"]` = "8773" - Port on which AWS EC2 compatible Admin API runs
* `default["nova"]["services"]["ec2-admin"]["network"]` = "public" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["ec2-admin"]["path"]` = "/services/Admin" - The path after host to this endpoint

* `default["nova"]["services"]["xvpvnc"]["scheme"]` = "http" - Protocol used for the xvp VNC Proxy endpoint
* `default["nova"]["services"]["xvpvnc"]["port"]` = "6081" - Port on which xvp VNC Proxy runs
* `default["nova"]["services"]["xvpvnc"]["network"]` = "nova" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["xvpvnc"]["path"]` = "/console" - The path after host to this endpoint

* `default["nova"]["services"]["novnc"]["scheme"]` = "http" - Protocol used for the noVNC Proxy endpoint
* `default["nova"]["services"]["novnc"]["port"]` = "6080" - Port on which noVNC Proxy runs
* `default["nova"]["services"]["novnc"]["network"]` = "nova" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["novnc"]["path"]` = `"/vnc_auto.html"` - The path after host to this endpoint

* `default["nova"]["services"]["novnc-server"]["scheme"]` = "http" - Protocol used for the noVNC Server endpoint
* `default["nova"]["services"]["novnc-server"]["port"]` = "6080" - Port on which noVNC Server runs
* `default["nova"]["services"]["novnc-server"]["network"]` = "nova" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["novnc-server"]["path"]` = `"/vnc_auto.html"` - The path after host to this endpoint

* `default["nova"]["services"]["volume"]["scheme"]` = "http" - Protocol used for the OpenStack Volume API endpoint
* `default["nova"]["services"]["volume"]["port"]` = "8776" - Port on which OpenStack Volume API runs
* `default["nova"]["services"]["volume"]["network"]` = "public" - The name of the network the IP address for this endpoint should come from
* `default["nova"]["services"]["volume"]["path"]` = "/v1/`%(tenant_id)s`" - The path after host to this endpoint

Networking Attributes
---------------------

Basic networking configuration is controlled with the following attributes:

* `default["nova"]["network"]["network_manager"]` - Defaults to "nova.network.manager.FlatDHCPManager". Set to "nova.network.manager.VlanManager" to configure VLAN Networking.
* `default["nova"]["network"]["fixed_range"]` - The CIDR for the network that VMs will be assigned to. In the case of VLAN Networking, this should be the network in which all VLAN networks that tenants are assigned will fit.
* `default["nova"]["network"]["dmz_cidr"]` - A CIDR for the range of IP addresses that will NOT be SNAT'ed by the nova network controller
* `default["nova"]["network"]["public_interface"]` - Defaults to eth0. Refers to the network interface used for VM addresses in the `fixed_range`.
* `default["nova"]["network"]["vlan_interface"]` - Defaults to eth0. Refers to the network interface used for VM addresses when VMs are assigned in a VLAN subnet.

You can have the cookbook automatically create networks in Nova for you by adding a Hash to the `default["nova"]["networks"]` Array.
**Note**: The `nova::nova-setup` recipe contains the code that creates these pre-defined networks.

Each Hash must contain the following keys:

* `ipv4_cidr` - The CIDR representation of the subnet. Supplied to the nova-manage network create command as `--fixed_ipv4_range`
* `label` - A name for the network

In addition to the above required keys in the Hash, the below keys are optional:

* `num_networks` - Passed as-is to `nova-manage network create` as the `--num_networks` option. This overrides the default `num_networks` nova.conf value.
* `network_size` - Passed as-is to `nova-manage network create` as the `--network_size` option. This overrides the default `network_size` nova.conf value.
* `bridge` - Passed as-is to `nova-manage network create` as the `--bridge` option.
* `bridge_interface` -- Passed as-is to `nova-manage network create` as the `--bridge_interface` option. This overrides the default `vlan_interface` nova.conf value.
* `dns1` - Passed as-is to `nova-manage network create` as the `--dns1` option.
* `dns2` - Passed as-is to `nova-manage network create` as the `--dns2` option.
* `multi_host` - Passed as-is to `nova-manage network create` as the `--multi_host` option. Values should be either 'T' or 'F'
* `vlan` - Passed as-is to `nova-manage network create` as the `--vlan` option. Should be the VLAN tag ID.

By default, the `default["nova"]["networks"]` array has two networks:

* `default["nova"]["networks"]["public"]["label"]` - Network label to be assigned to the public network on creation
* `default["nova"]["networks"]["public"]["ipv4_cidr"]` - Network to be created (in CIDR notation, e.g., 192.168.100.0/24)
* `default["nova"]["networks"]["public"]["num_networks"]` - Number of networks to be created
* `default["nova"]["networks"]["public"]["network_size"]` - Number of IP addresses to be used in this network
* `default["nova"]["networks"]["public"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br100)
* `default["nova"]["networks"]["public"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth2)
* `default["nova"]["networks"]["public"]["dns1"]` - DNS server 1
* `default["nova"]["networks"]["public"]["dns2"]` - DNS server 2

* `default["nova"]["networks"]["private"]["label"]` - Network label to be assigned to the private network on creation
* `default["nova"]["networks"]["private"]["ipv4_cidr"]` - Network to be created (in CIDR notation e.g., 192.168.200.0/24)
* `default["nova"]["networks"]["private"]["num_networks"]` - Number of networks to be created
* `default["nova"]["networks"]["private"]["network_size"]` - Number of IP addresses to be used in this network
* `default["nova"]["networks"]["private"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br200)
* `default["nova"]["networks"]["private"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth3)

Libvirt Configuration Attributes
---------------------------------

* `default["nova"]["libvirt"]["virt_type"]` - What hypervisor software layer to use with libvirt (e.g., kvm, qemu)
* `default["nova"]["libvirt"]["vncserver_listen"]` - IP address on the hypervisor that libvirt listens for VNC requests on
* `default["nova"]["libvirt"]["vncserver_proxyclient_address"]` - IP address on the hypervisor that libvirt exposes for VNC requests on (should be the same as `vncserver_listen`)
* `default["nova"]["libvirt"]["auth_tcp"]` - Type of authentication your libvirt layer requires
* `default["nova"]["libvirt"]["ssh"]["private_key"]` - Private key to use if using SSH authentication to your libvirt layer
* `default["nova"]["libvirt"]["ssh"]["public_key"]` - Public key to use if using SSH authentication to your libvirt layer

Scheduler Configuration Attributes
----------------------------------

* `default["nova"]["scheduler"]["scheduler_driver"]` - the scheduler driver to use
NOTE: The filter scheduler currently does not work with ec2.
* `default["nova"]["scheduler"]["default_filters"]` - a list of filters enabled for schedulers that support them.

Syslog Configuration Attributes
-------------------------------

* `default["nova"]["syslog"]["use"]` - Should nova log to syslog?
* `default["nova"]["syslog"]["facility"]` - Which facility nova should use when logging in python style (for example, `LOG_LOCAL1`)
* `default["nova"]["syslog"]["config_facility"]` - Which facility nova should use when logging in rsyslog style (for example, local1)

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
