# Application functionality

TimeTracker is for teams that report their working hours. A **timesheet** is a
shared place to log time, with fields chosen by its admins (project, task,
notes, ...). Members log **time entries** in it, admins invite people, see
everybody's entries and compare the logged hours with the hours planned for a
**period**, for example a semester.

## Roles and permissions

Every page needs a signed-in user. Inside a timesheet a person is a **user**
(a member) or an **admin**. A **superadmin** is an admin of every timesheet.

| Capability | Signed in | Member (user) | Timesheet admin | Superadmin |
| --- | --- | --- | --- | --- |
| Create a timesheet (and become its admin) | Yes | Yes | Yes | Yes |
| Join a timesheet with an invitation | Yes | Yes | Yes | Yes |
| Log, edit and delete own time entries | No | Yes | Yes | Yes |
| See own totals, top values, export own entries | No | Yes | Yes | Yes |
| Leave the timesheet | No | Yes | Yes | Yes |
| See and export the entries of other members | No | No | Yes | Yes |
| Change the name and fields, delete the timesheet | No | No | Yes | Yes |
| Invite people, remove members, change roles | No | No | Yes | Yes |
| Manage periods, planned hours and statistics | No | No | Yes | Yes |
| See every timesheet | No | No | No | Yes |

There is no page to make someone a superadmin, it's a flag on the user in the
database:

```bash
bin/rails runner 'User.find_by!(email: "someone@example.org").update!(superadmin: true)'
```

## Timesheets and fields

**Timesheets** in the top menu lists the timesheets of the signed-in user with
their role. **Add timesheet** creates a new one, its creator becomes its admin.

A timesheet has a name and at least one field. Every field has:

- a **title**, shown in the entry form and the table, its machine name (used in
  the CSV export) is made from it, e.g. "Client matter" becomes
  `client_matter`;
- a **type**: short text (one line, completes values the user entered before)
  or long text;
- **Show top values in sidebar**: the sidebar lists the values the user enters
  most often in this field, clicking one starts a new entry with it;
- **Show in table**: the field is a column of the time entries table, otherwise
  it's only in the entry form and the CSV export;
- an **access key**: Alt + the key jumps to the field in the entry form (Alt+T
  is the time, Alt+A the date).

Fields can be reordered and removed. Removing a field removes its values from
all entries.

Admins can delete a timesheet, with all its entries, periods, members and
invitations. Every member can **leave** a timesheet, their entries stay in it.
Nothing stops the last admin from leaving, then only a superadmin can manage
the timesheet.

## Time entries

**Time entries** in the top menu shows the entries of the selected timesheet
for one month. The sidebar switches timesheets.

### Log time

**Add time entry** opens the entry form: the timesheet fields, the time spent
(from 0.25 hours, in steps of 0.25) and the date (today by default). Entries can
be edited, deleted (after a confirmation) or cloned: the clone opens the form
with the same values and today's date.

People only edit and delete their own entries, also when they see the entries
of others.

### Months and totals

- **Previous month** and **Next month** move between months, the month button
  lists every month with entries.
- **Totals** in the sidebar has the hours in the timesheet and in the shown
  month.
- **Daily Totals** (or **Weekly Totals**, switched in its menu) has the hours
  per day or week of the shown month.

### Export

**Export time entries to CSV** (the menu next to the month) downloads the
entries of the shown month: email, date, hours and a column per field. A value
that a spreadsheet would run as a formula (starting with `=`, `+`, `-` or `@`)
gets a `'` in front, numbers stay as they are.

### Entries of other members

Admins see a people icon next to the month: **View time entries of other
users** lets them pick members of the timesheet. Then the list, the totals and
the CSV export are about the selected people, with an email column. **Show
only my entries** goes back. The selection is kept for the session, the top
values are hidden while it's on.

## Members and invitations

### Invite people

The invitation page of a timesheet takes email addresses (one per line, or
separated by commas or spaces) and the role they get. Every address gets an
email with its own link, `<site>/join/<code>`. A link:

- works for 7 days;
- works only for the account with the invited email (any letter case), so the
  invited person signs in (or signs up) first;
- works once.

Joining fails when the person is already a member. Emails are only sent when
the server can send email (see [Email](configuration.md#email)).

The data model also has **open invitations**: a link without an email that
anybody can use until it expires. There's no page to make one yet (the demo
data has one).

### Manage members

The **Users** page of a timesheet lists its members with the date they joined,
filtered by role (Users, Admins, All). Admins can:

- **remove** members, after a confirmation, they can't use the timesheet any
  more;
- **change the role** of one or several selected members.

## Periods and statistics

A **period** is a time span, e.g. a semester, with the hours every member
should work in it. Admins manage them on the **Periods** page of a timesheet.

### Set up a period

- **Add period**: a name, the first and the last day (not before the first),
  and optional fields for information about each person, e.g. funding source or
  supervisor (short text).
- **Set period hours**: the planned hours of every member and their values of
  the period fields. Hours can be set for all selected members at once.
- **Clone period**: a copy named "<name> clone", with the same dates, planned
  hours and fields (the values of the fields are not copied).
- **Delete period**, after a confirmation.

### Statistics

The statistics of a period list every member with planned hours (members
without planned hours are not in the list):

| Column | |
| --- | --- |
| Hours | the planned hours |
| Total hours | the hours logged in the timesheet from the first to the last day of the period |
| Should have now | the planned hours times the part of the period's days that passed, today included (0 before the period, all of them after it) |
| Balance | total hours minus should have now, negative balances are red |
| Balance percentage | total hours as a percentage of should have now |
| Last entry date | the last entry of the person in the period |
| Period fields | the values set on the period hours page |

The list can be sorted by every column, filtered by role (Users, Admins, All)
and with **Filter list** (identifier, ranges of hours, balance and last entry
date, field values). **Download CSV** exports the listed people, with the same
formula protection as the time entries. Clicking a row opens the entries of
that person in the period.

## Accounts and sign in

An installation uses one way to sign in, set with `DEVISE_AUTH_TYPE` (details
in [Authentication](configuration.md#authentication)):

| Mode | Behavior |
| --- | --- |
| `db` | Sign up with email and password (at least 6 characters), password reset by email, remember me. With `DEVISE_CONFIRMABLE=true` new accounts confirm their email first. |
| `cas` | CAS single sign-on, users are made on their first sign in and found by their email. Signing out also signs out from CAS. |
| `saml` | SAML single sign-on, users are made and updated from the SAML attributes, access can require a group. |
| `headers` | An authenticating proxy sends `X-Auth-Email` and `X-Auth-Name` with every request, the user is made or updated from them. Only requests from the proxy's addresses (`AUTH_HEADERS_TRUSTED_PROXIES`) are accepted. |

## Operational endpoints

- `GET /ping` answers the version of the front-end (`{"version": "3f9a1c0b7d2e"}`)
  to a signed-in user and 401 to anyone else, without a redirect to sign in.
  The version is a digest of the front-end page, so every build has a new one,
  the page gets it too (`timetracker-version` meta tag).

## Sessions, connection and new versions

The front-end pings the server every minute:

- The session ended (401, or a redirect to a sign in page of an auth proxy):
  the page is reloaded, so the user lands on the sign in page.
- The server can't be reached (no network, the app restarts, a proxy answers
  5xx, no answer in 10 seconds): the page stays, a notice says changes can't be saved, the ping is tried
  every 10 seconds until the server is back.
- A new version was deployed: a notice says so with a reload button, and the
  next page the user opens is loaded from the server, not in place. Nothing
  typed on the current page gets lost.

The files of the old front-end are gone after a deploy (they get 404), so a tab
opened before it can't open a page whose files it didn't load yet. Then the
page is loaded from the server, if the server can be reached, not again within
10 seconds, so a broken deploy doesn't load the page forever.
