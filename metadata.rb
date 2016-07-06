name 'openstack-compute'
maintainer 'openstack-chef'
maintainer_email 'openstack-dev@lists.openstack.org'
issues_url 'https://launchpad.net/openstack-chef' if respond_to?(:issues_url)
source_url 'https://github.com/openstack/cookbook-openstack-compute' if respond_to?(:source_url)
license 'Apache 2.0'
description 'The OpenStack Compute service Nova.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '14.0.0'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'ceph', '>= 0.8.1'
depends 'openstack-common', '>= 14.0.0'
depends 'openstack-identity', '>= 14.0.0'
depends 'openstack-image', '>= 14.0.0'
depends 'openstack-network', '>= 14.0.0'
depends 'python', '~> 1.4.6'
