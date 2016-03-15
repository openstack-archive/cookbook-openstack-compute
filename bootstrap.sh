#!/bin/bash -x
## This script is for installing all the needed packages on trusty to run the chef tests with 'chef exec rake'.
## It relies on the common bootstrap.sh from openstack/cookbook-openstack-common for installing common dependencies.

wget -nv -t 3 -O common-bootstrap.sh https://raw.githubusercontent.com/openstack/cookbook-openstack-common/master/bootstrap.sh
/bin/bash -x common-bootstrap.sh
