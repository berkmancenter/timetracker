[![Build Status](https://circleci.com/gh/berkmancenter/timetracker.svg?style=shield)](https://circleci.com/gh/berkmancenter/timetracker)

# TimeTracker

TimeTracker is a simple open-source time reporting application. People log
their hours in shared timesheets, timesheet admins invite people, see
everybody's hours and compare them with the hours planned for a period.
Powered by Ruby on Rails, PostgreSQL and a Vue front-end.

## Documentation

- [Application functionality](docs/app-functionality.md)
- [Configuration](docs/configuration.md)
- [Documentation index](docs/README.md)
- [User manual](docs/user-manual/README.md)

## Development

```bash
./docker/start_dev.sh --demo   # app + database, with demo data to play with
./docker/shell_dev.sh          # shell in the app container
./docker/stop_dev.sh           # stop it (-v also drops the database)
```

The app runs on http://127.0.0.1:6868, sent emails show up in Mailcatcher on
http://127.0.0.1:6878. `start_dev.sh` passes other arguments to
`docker compose up`, e.g. `-d` to run in the background or `--build` after a
Dockerfile change.

The settings are in `.env.development`, made from `.env.sample` on the first
start (Docker Compose reads the database settings from `.env`, also made from
`.env.sample`), see [Configuration](docs/configuration.md). After changing a
`VITE_` setting, start again: the container builds the front-end on every
start.

### Building

| What | Command |
| --- | --- |
| Front-end (Vue, `front/`) into `public/` | `./docker/shell_dev.sh bin/compile-front.sh` |
| Rails assets into `public/assets` (production) | `./docker/shell_dev.sh bin/compile-assets.sh` |

The front-end is served from the build in `public/`, so build it again after
changing it. For live reloading run the Vite dev server instead:
`./docker/shell_dev.sh bash -c "cd front && yarn dev"`, it runs on
http://127.0.0.1:6767 and talks to the app on port 6868 (`VITE_API_URL`), sign
in there first.

The Rails assets are compiled on request in development, precompiled ones in
`public/assets` would be used instead of your changes
(`bin/rails assets:clobber` removes them). Production images precompile both
during `docker build`.

### Tests

```bash
./docker/test.sh                     # back-end and front-end tests
./docker/test.sh back                # only rspec
./docker/test.sh back spec/models    # rspec with arguments
./docker/test.sh front               # only vitest
```

The tests run in their own containers (`docker/docker-compose.test.yml`), next
to the development ones. The code is copied into the test image, so the image is
built again when the code changed, the test database is made again from the
migrations on every run.

## Demo data

The seeds are demo data: people with different roles, three timesheets with
their own fields, months of time entries, periods with planned hours and
invitations in every state. Everything you need to click through the app
without making it all by hand.

### Loading it

| What | With Docker | Without Docker |
| --- | --- | --- |
| Load on every start | `./docker/start_dev.sh --demo` | |
| Load (again) | `./docker/seed_dev.sh` | `bin/rails demo:load` |
| Remove and load again | `./docker/seed_dev.sh reset` | `bin/rails demo:reset` |
| Remove | `./docker/seed_dev.sh remove` | `bin/rails demo:remove` |
| Show accounts, links and things to try | `./docker/seed_dev.sh info` | `bin/rails demo:info` |

A new development database gets the demo data automatically (`db:prepare` runs
the seeds), so does `bin/setup --demo`. To always load it with Docker, put
`SEED_DEMO_DATA=true` in `.env.development`.

Loading again puts the demo data back to its starting state: demo timesheets
get their name, fields and periods back, entries made by demo users are made
again, used invitations can be used again, and accounts signed up with a demo
email are removed. Your own users and timesheets are never touched.

Demo users are the ones with a `@demo.timetracker.test` email, demo timesheets
have a fixed UUID made from their key (so their links stay the same). If you
join a demo timesheet with your own account, you stay a member when the demo
data is loaded again. Removing the demo data removes the demo timesheets with
everything in them, also your entries there.

### Accounts

Every account has the password `timetracker-demo-password` (with
`DEVISE_AUTH_TYPE=db`; with `headers` send the email in `X-Auth-Email`, CAS and
SAML match demo users by their email).

| Email | Who |
| --- | --- |
| `admin@demo.timetracker.test` | Ada, superadmin, sees and manages every timesheet |
| `maya@demo.timetracker.test` | Maya, runs the Research Lab, admin there and in the Writing group |
| `jonas@demo.timetracker.test` | Jonas, research assistant in the lab, also works in the Legal Clinic |
| `priya@demo.timetracker.test` | Priya, admin of the Legal Clinic, research assistant in the lab, ahead of her hours |
| `sam@demo.timetracker.test` | Sam, research assistant, behind: logs less than planned and nothing in the last 10 days |
| `tom@demo.timetracker.test` | Tom, joined the Legal Clinic 3 weeks ago, his invitation to the lab expired |
| `lea@demo.timetracker.test` | Lea, invited to the Research Lab, hasn't joined yet |
| `nora@demo.timetracker.test` | Nora, in no timesheet, can join the Writing group with its open link |

### Timesheets

| Timesheet | Fields | Members | Periods |
| --- | --- | --- | --- |
| Research Lab | Project, Activity, Notes (long text) | Maya (admin), Jonas, Priya, Sam | Last term, Current term, Next term (not started) |
| Legal Clinic | Client matter, Task, Description (long text, not in the table) | Priya (admin), Jonas, Tom | Clinic semester |
| Writing group | What I worked on | Maya (admin), Priya | none |

The periods have planned hours for each person and the period fields "Funding
source" and "Supervisor". Time entries are generated on weekdays for the last
240 days (from the day a person joined), plus a few written ones: a long note
and a note starting with `=` (the CSV export keeps it as text).

### Things to try

`./docker/seed_dev.sh info` prints these with the links of your installation.

- Log in as Maya and add a time entry in the Research Lab: the sidebar has her
  most used projects and activities, the short text fields complete what she
  typed before. The people icon next to the month shows the entries of the
  others.
- As Maya, open Timesheets → Research Lab → Periods → "Current term"
  statistics: Priya is ahead, Sam is behind. Click a row to see the entries of
  that person in the period, download the CSV.
- Log in as Lea and open http://127.0.0.1:6868/join/demo-lab-lea to join the
  Research Lab.
- Log in as Tom and open http://127.0.0.1:6868/join/demo-lab-tom: his
  invitation expired.
- Log in as Nora (or your own account) and open
  http://127.0.0.1:6868/join/demo-writing-group, the open link works for
  anybody until it expires.
- Sign up as `rosa@demo.timetracker.test`, then open
  http://127.0.0.1:6868/join/demo-clinic-rosa to join the Legal Clinic as admin.
- Log in as Ada: as superadmin she sees every timesheet.

### Options

| Variable | Default | |
| --- | --- | --- |
| `DEMO_HISTORY_DAYS` | `240` | how many days back time entries are generated, e.g. `730` for long lists |
| `DEMO_PASSWORD` | `timetracker-demo-password` | password of every demo account |
| `DEMO_RANDOM_SEED` | `2012` | another number gives other generated entries |

For example `DEMO_HISTORY_DAYS=730 ./docker/seed_dev.sh reset`.

The data is in [db/seeds/demo_data.yml](db/seeds/demo_data.yml), easy to
change or extend, the code that loads it is in
[lib/timetracker/demo_data.rb](lib/timetracker/demo_data.rb). The same data
comes out on every run, dates are relative to today.

The demo accounts have a known password, so the demo data never loads in
production (seeds there do nothing). For a demo server set
`ALLOW_DEMO_DATA=true`.

## License

This application is released under a GPLv3 license.

## Copyright

© 2012 President and Fellows of Harvard College
