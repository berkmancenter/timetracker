# Configuration

TimeTracker is configured with environment variables. This page lists what
each of them does. [.env.sample](../.env.sample) has a starting point.

## Environment files

In the development and test containers,
[docker/entrypoint.sh](../docker/entrypoint.sh) reads `.env.$APP_ENV`
(`.env.development`, `.env.test`) on every start:

- when the file is missing, it's made from `.env.sample`, with every
  "development" replaced by the environment name;
- its variables are exported for the app, and shells in the container
  (`./docker/shell_dev.sh`) load it too;
- its `VITE_` lines are copied to `front/.env`, then the front-end is built.

Docker Compose itself reads `.env` for the database container
(`DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_DB_NAME`).

Without Docker, Rails loads `.env.<RAILS_ENV>` and `.env` (dotenv), variables
already set in the environment win.

### Production

The production image (the default target of
[docker/Dockerfile](../docker/Dockerfile)) has the Rails assets and the
front-end built in, its entrypoint doesn't make env files or build anything.
Make `.env.production` from `.env.sample` yourself, with a new
`SECRET_KEY_BASE` and `SMTP_ADDRESS`, then:

```bash
docker compose -f docker/docker-compose.prod.yml --env-file .env.production up -d --build
```

With `--env-file` Compose takes from the file the database settings and the
[front-end build settings](#front-end), the app container gets the whole file
as its environment. `APP_PORT` (default 6868) is the port on the host.

## Application

| Variable | Default | |
| --- | --- | --- |
| `APP_ENV` | | `development`, `test` or `production`, picks the env file in Docker |
| `RAILS_ENV` | `development` | the Rails environment, the same as `APP_ENV` |
| `SECRET_KEY_BASE` | | signs the session cookies in production (development and test make their own). The development and test containers put a new one in new env files, and in env files without one or with the public key that `.env.sample` used to have (this signs everybody out once). For production make one with `bin/rails secret`, production containers don't start with the public key |
| `FRONT_URL` | `https://example.com` | the address of the site, used for the links in invitation emails (`<FRONT_URL>/join/<code>`) and as SAML base URL |
| `ALLOWED_HOST` | | when set, production only answers requests for this host name |
| `CORS_ALLOWED_ORIGINS` | | comma separated origins allowed to call the app from another origin with cookies, e.g. the Vite dev server `http://127.0.0.1:6767` |
| `RAILS_SERVE_STATIC_FILES` | | any value: production serves `public/` itself (front-end and assets), leave it empty when a web server in front does that |
| `RAILS_LOG_LEVEL` | `debug` (development), `info` (production) | |
| `PORT` | `3000` | port of the app server (Puma) |
| `RAILS_MAX_THREADS` | `3` | Puma threads, also the database pool size when `DATABASE_POOL` is not set |

## Database

PostgreSQL, settings in [config/database.yml](../config/database.yml).

| Variable | Default | |
| --- | --- | --- |
| `DATABASE_HOST` | | `db` in Docker |
| `DATABASE_PORT` | `5432` | |
| `DATABASE_USERNAME` | | |
| `DATABASE_PASSWORD` | | |
| `DATABASE_DB_NAME` | | |
| `DATABASE_POOL` | `RAILS_MAX_THREADS`, or 5 | connections per process |
| `DATABASE_TIMEOUT` | `5000` | milliseconds |

## Authentication

`DEVISE_AUTH_TYPE` picks how people sign in: `db` (default), `cas`, `saml` or
`headers`. The front-end needs the same value in `VITE_AUTH_TYPE`, it uses it
to sign out the right way.

### Database (`db`)

Email and password accounts with sign up, password reset and remember me.

| Variable | Default | |
| --- | --- | --- |
| `DEVISE_CONFIRMABLE` | | `true`: new accounts have to confirm their email before they can sign in |

### CAS (`cas`)

Users are made on their first sign in, the CAS `mail` attribute is their
email. Signing out also signs out from CAS.

| Variable | Default | |
| --- | --- | --- |
| `DEVISE_CAS_AUTH_URL` | `https://cas.example.com` | the CAS server |
| `DEVISE_CAS_AUTH_SERVICE_PATH` | `/users/service` | the service path in this app |

### SAML (`saml`)

Users are made on their first sign in and updated on every sign in from the
SAML attributes. The service provider metadata is at `/users/saml/metadata`.

| Variable | Default | |
| --- | --- | --- |
| `DEVISE_SAML_BASE_URL` | `FRONT_URL` | the address of this app, for the URLs below |
| `DEVISE_SAML_ASSERTION_CONSUMER_SERVICE_URL` | `<base>/users/saml/auth` | |
| `DEVISE_SAML_SP_ENTITY_ID` | `<base>/users/saml/metadata` | |
| `DEVISE_SAML_SIGN_OUT_SUCCESS_URL` | `FRONT_URL` | where people land after signing out |
| `DEVISE_SAML_IDP_ENTITY_ID` | | the identity provider |
| `DEVISE_SAML_IDP_SSO_SERVICE_URL` | | its sign in URL |
| `DEVISE_SAML_IDP_SLO_SERVICE_URL` | | its sign out URL |
| `DEVISE_SAML_IDP_CERT` | | its certificate, `\n` for new lines |
| `DEVISE_SAML_IDP_CERT_FINGERPRINT` | | instead of the certificate |
| `DEVISE_SAML_IDP_CERT_FINGERPRINT_ALGORITHM` | SHA-256 | |
| `DEVISE_SAML_DEFAULT_USER_KEY` | `email` | the user column people are found by |
| `DEVISE_SAML_USE_SUBJECT` | | `true`: find people by the NameID instead of an attribute |
| `DEVISE_SAML_NAME_IDENTIFIER_FORMAT` | email address | |
| `DEVISE_SAML_ASSERTION_CONSUMER_SERVICE_BINDING` | HTTP-POST | |
| `DEVISE_SAML_AUTHN_CONTEXT` | | |
| `DEVISE_SAML_VALIDATE_IN_RESPONSE_TO` | | `true`: check that a response answers a request of this app |
| `DEVISE_SAML_ALLOWED_CLOCK_DRIFT` | `0` | seconds of clock difference to accept |
| `DEVISE_SAML_EMAIL_ATTRIBUTE` | | comma separated attribute names for the email, on top of the usual ones (`email`, `mail`, ...) |
| `DEVISE_SAML_FIRST_NAME_ATTRIBUTE` | | the same for the first name (`givenName`, ...) |
| `DEVISE_SAML_LAST_NAME_ATTRIBUTE` | | the last name (`sn`, `surname`, ...) |
| `DEVISE_SAML_DISPLAY_NAME_ATTRIBUTE` | | the display name, used when the first or last name is missing |
| `DEVISE_SAML_MEMBER_OF_ATTRIBUTE` | | the groups (`memberOf`, ...) |
| `DEVISE_SAML_REQUIRED_MEMBER_OF` | | comma separated groups, when set only members of one of them can sign in |

An empty value (like `DEVISE_SAML_SP_ENTITY_ID=` in `.env.sample`) means the
default.

### Headers (`headers`)

An authenticating proxy in front of the app signs people in and sends
`X-Auth-Email` and `X-Auth-Name` with every request. Without both headers, or
from an address that is not a trusted proxy, a request gets 401. The user is
found by the email (any letter case) or made, and the name is updated from
`X-Auth-Name`. Signing out is up to the proxy.

| Variable | Default | |
| --- | --- | --- |
| `AUTH_HEADERS_TRUSTED_PROXIES` | `127.0.0.1,::1` | comma separated IPs or CIDR ranges the headers are accepted from |

The address checked is the direct peer of the app (`REMOTE_ADDR`), not
`X-Forwarded-For`, so a browser can't pretend to be the proxy. In Docker the
proxy connects from the Docker network, not from loopback: use its gateway or
range, e.g. `172.16.0.0/12` (`docker network inspect <network>` shows it). The
proxy still has to replace these headers in requests coming from browsers.

## Email

The app sends invitation emails, and in `db` mode the Devise emails (password
reset, confirmation).

| Variable | Default | |
| --- | --- | --- |
| `SMTP_ADDRESS` | | the SMTP server. Production containers don't start without it, development and test ones use Mailcatcher when it's empty |
| `SMTP_PORT` | | |
| `SMTP_DOMAIN` | | HELO domain |
| `SMTP_USERNAME` | | log in to the SMTP server with this user, no login when empty |
| `SMTP_PASSWORD` | | |
| `SMTP_AUTHENTICATION` | `plain` | `plain`, `login` or `cram_md5`, used with `SMTP_USERNAME` |
| `SMTP_OPENSSL_VERIFY_MODE` | `peer` | `peer` checks the server certificate, `none` only for a trusted relay with a self-signed certificate |
| `MAILER_DELIVERY_METHOD` | `smtp` (production), `test` (development) | `test` only keeps emails in memory, `smtp` in development sends them to Mailcatcher (http://127.0.0.1:6878) |
| `DEFAULT_SENDER` | `no-reply@example.com` | the From address |
| `RETURN_PATH` | `user@example.com` | where bounces go |
| `EMAIL_DOMAIN` | `example.com` | host of the links in Devise emails in production (`SMTP_HOST` in development) |

## Front-end

The Vue front-end gets these at build time: change them, then build it again
(`bin/compile-front.sh`, or restart the container). The production image gets
them as build arguments when it's built (`docker build --build-arg`, or the
`--env-file` of the production Compose file), `VITE_ENVIRONMENT` is always
`production` there.

| Variable | Default | |
| --- | --- | --- |
| `VITE_API_URL` | | the address of the app the front-end talks to, e.g. `http://127.0.0.1:6868`, empty: the address of the page |
| `VITE_AUTH_TYPE` | | the same as `DEVISE_AUTH_TYPE` |
| `VITE_BASE_PATH` | `/` | when the app runs in a sub folder, e.g. `/timetracker/` |
| `VITE_ENVIRONMENT` | | `development`: requests send cookies to another origin too (for the Vite dev server) |

## Demo data

See [Demo data](../README.md#demo-data).

| Variable | Default | |
| --- | --- | --- |
| `SEED_DEMO_DATA` | | `true`: the development Docker setup loads the demo data on every start |
| `DEMO_HISTORY_DAYS` | `240` | how many days back time entries are generated |
| `DEMO_PASSWORD` | `timetracker-demo-password` | password of every demo account |
| `DEMO_RANDOM_SEED` | `2012` | another number gives other generated entries |
| `ALLOW_DEMO_DATA` | | `true`: allow the demo data outside development and test, e.g. on a demo server |
