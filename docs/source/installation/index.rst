############
Installation
############

You can pull the code from https://github.com/berkmancenter/timetracker.

The first time
==============

- Follow the steps for development.

Every time
==========

- ``git pull``
- ``bundle install``
- ``rails assets:clobber && rails assets:precompile`` if assets changes.
- ``rails db:migrate`` if db schema changes.
- ``cd front && ./deploy.sh`` if you had changes in the Vue application.
-  Run your web server, whatever it is (e.g. https://github.com/phusion/passenger) in the ``production`` environment (RAILS_ENV=production).
