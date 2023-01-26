# Time Tracker

Time Tracker is a simple open-source time reporting application.

## Stack
* Ruby `3.0.x`
* Ruby on Rails `7.0.x`
* PostgreSQL `9.x` - `14.x`
* Bundler
* Yarn

## Development

* `docker-composer up`
* `docker-compose exec website bash`
* `bundle install`
* Copy `config/database.yml.example` to `config/database.yml` and set up your database accordingly.
* Copy `config/secrets.yml.example` to `config/secrets.yml` and fill in the `secret_key_base` values for dev/test.
* Add the following to .env:
  * `USE_FAKEAUTH` (optional; set to to `true` if you want to bypass CAS for development; any username/password will work; cannot be used in production).
  * `SECRET_KEY_BASE` (required in production, optional otherwise; use `rails secret` to generate a value).
  * `ALLOWED_HOST` (localhost is allowed by default; anything else must be explicit; may be a single string or a regex)
  * `CAS_DATA_DIRECTORY` (required in production, directory for storing CAS data, in development use `USE_FAKEAUTH`)
* `rails db:migrate`
* `rails s -b 0.0.0.0`

## Deployment

* The first time
  * Follow the steps above for development.
  * Make sure you've set the server hostname in ALLOWED_HOST.
* Every time
  * `git pull`
  * `bundle install`
  * `yarn install`
  * `rails assets:clobber && rails assets:precompile` if assets changes
  * `rails db:migrate` if db schema changes.
  * Run your web server, whatever it is (e.g. https://github.com/phusion/passenger).

## License

This application is released under a GPLv3 license.

## Copyright

2012-2023 President and Fellows of Harvard College