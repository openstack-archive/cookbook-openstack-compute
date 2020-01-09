source 'https://supermarket.chef.io'

solver :ruby, :required

%w(
  client
  -common
  -dns
  -identity
  -image
  -integration-test
  -network
  -ops-database
  -ops-messaging
).each do |cookbook|
  if Dir.exist?("../cookbook-openstack#{cookbook}")
    cookbook "openstack#{cookbook}", path: "../cookbook-openstack#{cookbook}"
  else
    cookbook "openstack#{cookbook}", git: "https://opendev.org/openstack/cookbook-openstack#{cookbook}"
  end
end

metadata
