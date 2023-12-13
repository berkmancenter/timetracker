###########
Development
###########

| Want to contribute to something cool?
| Join our team now!
| Your code can make a real impact.
| Check out the open issues, submit pull requests, and let's build something awesome together! 

https://github.com/berkmancenter/timetracker

Prerequisites
=============

- Docker Engine (https://docs.docker.com/engine/)
- Docker Compose (https://docs.docker.com/compose/)

Quick start
===========

-  ``docker-compose -f docker-compose.dev.yml --env-file .env.dev up``
-  ``docker-compose -f docker-compose.dev.yml --env-file .env.dev exec app bash``
-  ``bundle install``
-  ``cd front``
-  ``./deploy.sh``
-  ``cd ..``
-  ``rails db:migrate``
-  ``rails s -b 0.0.0.0``
-  Open ``http://127.0.0.1:6868``.
