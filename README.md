Team and repository tags
========================

[![Team and repository tags](https://governance.openstack.org/badges/cookbook-openstack-compute.svg)](https://governance.openstack.org/reference/tags/index.html)

<!-- Change things from this point on -->

![Chef OpenStack Logo](https://www.openstack.org/themes/openstack/images/project-mascots/Chef%20OpenStack/OpenStack_Project_Chef_horizontal.png)

Description
===========

This cookbook installs the OpenStack Compute service **Nova** as part of the
OpenStack reference deployment Chef for OpenStack. The
https://github.com/openstack/openstack-chef-repo contains documentation for using
this cookbook in the context of a full OpenStack deployment. Nova is currently
installed from packages.

https://docs.openstack.org/mitaka/config-reference/compute.html

Requirements
============

- Chef 12 or higher
- chefdk 0.9.0 or higher for testing (also includes berkshelf for cookbook
  dependency resolution)

Platform
========

- ubuntu
- redhat
- centos

Cookbooks
=========

The following cookbooks are dependencies:

- 'ceph', '>= 0.8.1'
- 'openstack-common', '>= 14.0.0'
- 'openstack-identity', '>= 14.0.0'
- 'openstack-image', '>= 14.0.0'
- 'openstack-network', '>= 14.0.0'
- 'openstackclient', '>= 0.1.0'

Attributes
==========

Please see the extensive inline documentation in `attributes/*.rb` for
descriptions of all the settable attributes for this cookbook.

Note that all attributes are in the `default['openstack']` "namespace"

The usage of attributes to generate the node.conf is decribed in the
openstack-common cookbook.

Recipes
=======

## openstack-compute::api-metadata
- Installs the nova metadata package

## openstack-compute::api-os-compute
- Installs OS API and configures the service and endpoints in keystone

## openstack-compute::client
- Install the nova client packages

## openstack-compute::compute
- Installs nova-compute service

## openstack-compute::compute
- Installs nova-conductor service

## openstack-compute::identity_registration
- Registers the nova endpoints with keystone

## openstack-compute::libvirt
- Installs libvirt, used by nova compute for management of the virtual machine
  environment

## openstack-compute::libvirt_rbd
- Prepares the compute node for interaction with a Ceph cluster for block
  storage (RBD)
- Depends on `ceph::_common`, `ceph::install`, and `ceph::conf` for packages and
  cluster connectivity (i.e. a proper `/etc/ceph/ceph.conf`)

## openstack-compute::nova-cert
- Installs nova-cert service

## openstack-compute::nova-common
- Builds the basic nova.conf config file with details of the rabbitmq, mysql,
  glance and keystone servers

## openstack-compute::nova-setup
- Sets up the nova networks with `nova-manage`

## openstack-compute::scheduler
- Installs nova scheduler service

## openstack-compute::vncproxy
- Installs and configures the vncproxy service for console access to VMs

## openstack-compute::serialproxy
- Installs and configures the serialproxy service for serial console access to VMs


License and Author
==================

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |  Justin Shepherd (<justin.shepherd@rackspace.com>) |
| **Author**           |  Jason Cannavale (<jason.cannavale@rackspace.com>) |
| **Author**           |  Ron Pedde (<ron.pedde@rackspace.com>)             |
| **Author**           |  Joseph Breu (<joseph.breu@rackspace.com>)         |
| **Author**           |  William Kelly (<william.kelly@rackspace.com>)     |
| **Author**           |  Darren Birkett (<darren.birkett@rackspace.co.uk>) |
| **Author**           |  Evan Callicoat (<evan.callicoat@rackspace.com>)   |
| **Author**           |  Matt Ray (<matt@opscode.com>)                     |
| **Author**           |  Jay Pipes (<jaypipes@att.com>)                    |
| **Author**           |  John Dewey (<jdewey@att.com>)                     |
| **Author**           |  Kevin Bringard (<kbringard@att.com>)              |
| **Author**           |  Craig Tracey (<craigtracey@gmail.com>)            |
| **Author**           |  Sean Gallagher (<sean.gallagher@att.com>)         |
| **Author**           |  Ionut Artarisi (<iartarisi@suse.cz>)              |
| **Author**           |  JieHua Jin (<jinjhua@cn.ibm.com>)                 |
| **Author**           |  David Geng (<gengjh@cn.ibm.com>)                  |
| **Author**           |  Salman Baset (<sabaset@us.ibm.com>)               |
| **Author**           |  Chen Zhiwei (<zhiwchen@cn.ibm.com>)               |
| **Author**           |  Mark Vanderwiel (<vanderwl@us.ibm.com>)           |
| **Author**           |  Eric Zhou (<zyouzhou@cn.ibm.com>)                 |
| **Author**           |  Mathew Odden (<mrodden@us.ibm.com>)               |
| **Author**           |  Jan Klare (<j.klare@cloudbau.de>)                 |
| **Author**           |  Christoph Albers (<c.albers@x-ion.de>)            |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2012-2013, Rackspace US, Inc.       |
| **Copyright**        |  Copyright (c) 2012-2013, Opscode, Inc.            |
| **Copyright**        |  Copyright (c) 2012-2013, AT&T Services, Inc.      |
| **Copyright**        |  Copyright (c) 2013, Craig Tracey                  |
| **Copyright**        |  Copyright (c) 2013-2014, SUSE Linux GmbH          |
| **Copyright**        |  Copyright (c) 2013-2014, IBM, Corp.               |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
