name             'openstack-compute'
maintainer       'openstack-chef'
maintainer_email 'openstack-discuss@lists.openstack.org'
issues_url       'https://launchpad.net/openstack-chef'
source_url       'https://opendev.org/openstack/cookbook-openstack-compute'
license          'Apache-2.0'
description      'The OpenStack Compute service Nova.'
version          '20.0.0'

chef_version '>= 16.0'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.1'
depends 'openstack-common', '>= 20.0.0'
depends 'openstack-identity', '>= 20.0.0'
depends 'openstack-image', '>= 20.0.0'
depends 'openstack-network', '>= 20.0.0'
depends 'openstackclient'
