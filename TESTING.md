# Testing the Cookbook #

This cookbook uses [chefdk](https://downloads.chef.io/chef-dk/) and [berkshelf](http://berkshelf.com/) to isolate dependencies. Make sure you have chefdk and the header files for `gecode` installed before continuing. Make sure that you're using gecode version 3. More info [here](https://github.com/opscode/dep-selector-libgecode/tree/0bad63fea305ede624c58506423ced697dd2545e#using-a-system-gecode-instead). For more detailed information on what needs to be installed, you can have a quick look into the bootstrap.sh file in this repository, which does install all the needed things to get going on ubuntu trusty. The tests defined in the Rakefile include lint, style and unit. For integration testing please refere to the [openstack-chef-repo](https://github.com/openstack/openstack-chef-repo).

We have three test suites which you can run either, individually (there are three rake tasks):

    $ chef exec rake lint
    $ chef exec rake style
    $ chef exec rake unit

or altogether:

    $ chef exec rake

The `rake` tasks will take care of installing the needed cookbooks with `berkshelf`.

## Rubocop  ##

[Rubocop](https://github.com/bbatsov/rubocop) is a static Ruby code analyzer, based on the community [Ruby style guide](https://github.com/bbatsov/ruby-style-guide). We are attempting to adhere to this where applicable, slowly cleaning up the cookbooks until we can turn on Rubocop for gating the commits.

## Foodcritic ##

[Foodcritic](http://acrmp.github.io/foodcritic/) is a lint tool for Chef cookbooks. We ignore the following rules:

* [FC003](http://acrmp.github.io/foodcritic/#FC003) These cookbooks are not intended for Chef Solo.
* [FC023](http://acrmp.github.io/foodcritic/#FC023) Prefer conditional attributes.

## Chefspec

[ChefSpec](https://github.com/sethvargo/chefspec) is a unit testing framework for testing Chef cookbooks. ChefSpec makes it easy to write examples and get fast feedback on cookbook changes without the need for virtual machines or cloud servers.
