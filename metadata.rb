name 'openstack-compute'
maintainer 'openstack-chef'
maintainer_email 'openstack-dev@lists.openstack.org'
issues_url 'https://launchpad.net/openstack-chef' if respond_to?(:issues_url)
source_url 'https://github.com/openstack/cookbook-openstack-compute' if respond_to?(:source_url)
license 'Apache 2.0'
description 'The OpenStack Compute service Nova.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '16.0.0'
chef_version '>= 12.5' if respond_to?(:chef_version)

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'ceph', '>= 0.9.2'
depends 'openstack-common', '>= 16.0.0'
depends 'openstack-identity', '>= 16.0.0'
depends 'openstack-image', '>= 16.0.0'
depends 'openstack-network', '>= 16.0.0'
depends 'openstackclient'
