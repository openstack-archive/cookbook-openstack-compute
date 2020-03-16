source 'https://supermarket.chef.io'

solver :ruby, :required

[
  %w(client dep),
  %w(-common dep),
  %w(-dns integration),
  %w(-identity dep),
  %w(-image dep),
  %w(-integration-test integration),
  %w(-network dep),
  %w(-ops-database integration),
  %w(-ops-messaging integration)
].each do |cookbook, group|
  if Dir.exist?("../cookbook-openstack#{cookbook}")
    cookbook "openstack#{cookbook}", path: "../cookbook-openstack#{cookbook}", group: group
  else
    cookbook "openstack#{cookbook}", git: "https://opendev.org/openstack/cookbook-openstack#{cookbook}", group: group
  end
end

metadata
