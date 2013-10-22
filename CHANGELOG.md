# CHANGELOG for cookbook-openstack-common

This file is used to list changes made in each version of cookbook-openstack-common.

## 7.0.2:
* Check the run_context.loaded_recipes rather than the run_list, since the
  'openstack-network::server' recipe is most likely contained in a role and
  not explicitly in the run_list.
* The sysctl cookbook is unused and was removed as a dependency.

## 7.0.1:
* Adding attributes for libvirtd.conf settings (max_clients, max_workers,
  max_requests, max_client_requests).

## 7.0.0:
* Initial release of cookbook-openstack-common.

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
