# Testing the Cookbook #

This cookbook uses [bundler](http://gembundler.com/) and [berkshelf](http://berkshelf.com/) to isolate dependencies.

To setup the dependencies:

    $ bundle install --path=.bundle # install gem dependencies
    $ bundle exec berks vendor .cookbooks # install cookbook dependencies and create the folder .cookbooks

To run the tests:

    $ export COOKBOOK='openstack-compute'
    $ bundle exec foodcritic -f any -t ~FC003 -t ~FC023 .cookbooks/$COOKBOOK
    $ bundle exec rubocop .cookbooks/$COOKBOOK
    $ bundle exec rspec --format documentation .cookbooks/$COOKBOOK/spec

## Rubocop  ##

[Rubocop](https://github.com/bbatsov/rubocop) is a static Ruby code analyzer, based on the community [Ruby style guide](https://github.com/bbatsov/ruby-style-guide). We are attempting to adhere to this where applicable, slowly cleaning up the cookbooks until we can turn on Rubocop for gating the commits.

## Foodcritic ##

[Foodcritic](http://acrmp.github.io/foodcritic/) is a lint tool for Chef cookbooks. We ignore the following rules:

* [FC003](http://acrmp.github.io/foodcritic/#FC003) These cookbooks are not intended for Chef Solo.
* [FC023](http://acrmp.github.io/foodcritic/#FC023) Prefer conditional attributes.

## Chefspec

[ChefSpec](http://code.sethvargo.com/chefspec/) is a unit testing framework for testing Chef cookbooks. ChefSpec makes it easy to write examples and get fast feedback on cookbook changes without the need for virtual machines or cloud servers.
