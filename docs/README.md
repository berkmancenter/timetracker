# TimeTracker documentation

TimeTracker is a time reporting application. People log their hours in shared
timesheets, every timesheet has its own fields (project, task, ...), and
timesheet admins compare the logged hours with the hours planned for a period.

## Guides

- [Application functionality](app-functionality.md) describes the website:
  roles and permissions, timesheets and their fields, time entries, members and
  invitations, periods and their statistics, and signing in.
- [Configuration](configuration.md) lists the settings of an installation:
  database, authentication (database, CAS, SAML or headers), email, front-end
  and demo data.
- [README](../README.md) has the development setup, the tests and the demo
  data.
- The [user guide](https://berkman-klein-center.gitbook.io/timetracker) shows
  the website step by step.

## Audience

| If you want to... | Start with... |
| --- | --- |
| Log your hours | [Time entries](app-functionality.md#time-entries) |
| Start a timesheet for your team | [Timesheets and fields](app-functionality.md#timesheets-and-fields) |
| Invite people or change their role | [Members and invitations](app-functionality.md#members-and-invitations) |
| Check who is behind on their hours | [Periods and statistics](app-functionality.md#periods-and-statistics) |
| Understand what each role can do | [Roles and permissions](app-functionality.md#roles-and-permissions) |
| Set up sign in with CAS, SAML or a proxy | [Authentication](configuration.md#authentication) |
| Install or configure a server | [Configuration](configuration.md) |
| Work on the code | [Development](../README.md#development) and [Demo data](../README.md#demo-data) |
