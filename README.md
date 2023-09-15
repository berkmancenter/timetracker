[![Build Status](https://circleci.com/gh/berkmancenter/timetracker.svg?style=shield)](https://circleci.com/gh/berkmancenter/timetracker)

# Time Tracker

Time Tracker is a simple open-source time reporting application.

## Stack
* Ruby
* Ruby on Rails
* PostgreSQL
* Vue
* Vite
* Bundler

## Development

* `docker-compose -f docker-compose.dev.yml --env-file .env.dev up`
* `docker-compose -f docker-compose.dev.yml --env-file .env.dev exec app bash`
* `bundle install`
* `cd front`
* `./deploy.sh`
* `cd ..`
* `rails db:migrate`
* `rails s -b 0.0.0.0`
* Open `http://127.0.0.1:6868`.

## Deployment

* The first time
  * Follow the steps above for development.
* Every time
  * `git pull`
  * `bundle install`
  * `rails assets:clobber && rails assets:precompile` if assets changes
  * `rails db:migrate` if db schema changes.
  * `cd front && ./deploy.sh` if you had changes in the Vue application
  * Run your web server, whatever it is (e.g. https://github.com/phusion/passenger) in the `production` environment (RAILS_ENV=production).

## Environment variables

### API (.env)

| Variable    | Description | Required |
| ----------- | ----------- | -------- |
| `SECRET_KEY_BASE` | Use `rails secret` to generate a value | `Yes` |
| `FRONT_URL` | Application URL | `Yes` |
| `DATABASE_USERNAME` | Database username | `Yes` |
| `DATABASE_PASSWORD` | Database password | `Yes` |
| `DATABASE_DB_NAME` | Database name | `Yes` |
| `DATABASE_HOST` | Database host | `Yes` |
| `DATABASE_PORT` | Database port, default `5432` | `No` |
| `DATABASE_TIMEOUT` | Database timeout, default `5000 ms` | `No` |
| `ALLOWED_HOST` | `localhost` is allowed by default, anything else must be explicit, may be a single string or a regex | `No` |
| `CORS_ALLOWED_ORIGINS` | Comma-separated list of CORS allowed origins | `No`
| `DEVISE_AUTH_TYPE` | Authentication type, allowed values are `db` and `cas`, default is `db` | `No` |
| `DEVISE_CAS_AUTH_URL` | CAS server URL | `Yes` when `DEVISE_AUTH_TYPE` is `cas`, optional otherwise |
| `DEVISE_CAS_AUTH_SERVICE_PATH` | CAS callback service path, use it only if you want to customize the path, usually not needed | `No` |
| `DEFAULT_SENDER` | Application emails sender e.g. `Tony Hawk <tony@example.com>` | `Yes` when `DEVISE_AUTH_TYPE` is `db`, optional otherwise |
| `RETURN_PATH` | Email address for bounced messages | `Yes` when `DEVISE_AUTH_TYPE` is `db`, optional otherwise |

### Front-end (front/.env)

| Variable    | Description | Required |
| ----------- | ----------- | -------- |
| `VITE_API_URL` | URL of the Rails API, in `development` it will most likely be `http://127.0.0.1:6868` | `Yes` |
| `VITE_SITE_URL` | URL of the Vue application, in `development` it will most likely be `http://127.0.0.1:6767` | `Yes` |
| `VITE_ENVIRONMENT` | Vue application environment, default is `development` | `No` |

## License

This application is released under a GPLv3 license.

## Copyright

2012-2023 President and Fellows of Harvard College
