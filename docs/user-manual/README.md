# TimeTracker user manual

TimeTracker is for logging the hours you work. You log them as **time
entries** in a **timesheet** that you share with your team, and the admins of
the timesheet can compare everybody's hours with the hours planned for a
**period**, for example a semester.

This manual shows the website step by step. The screenshots use the demo data
(see "Demo data" in the [README](../../README.md#demo-data)), so names and
numbers are made up.

## Pages

1. [The screen explained](ui-explained.md)
2. [Time entries](time-entries.md): log, edit, remove and clone entries,
   months, export, entries of other people
3. [Timesheets](timesheets.md): create and edit timesheets and their fields,
   invite people, manage members and roles
4. [Periods](periods.md): planned hours and statistics
5. [Notes for Harvard users](harvard-users.md)

## Main ideas

### Timesheets

- A timesheet holds time entries. Its admins choose its fields, for example
  Project, Activity and Notes.
- You can be in as many timesheets as you need and switch between them in the
  sidebar.
- Everybody can create a timesheet, its creator becomes its admin.
- Admins invite other people to the timesheet, as users or as admins.

### Time entries

- An entry has the time spent (in hours) and the date, both required, and a
  value for each field of the timesheet.
- You create, edit and remove your own entries only.

### Roles

The roles are set per timesheet: you can be an admin in one timesheet and a
user in another. Changing someone's role in one timesheet doesn't change it in
the others.

| What you can do | User | Admin |
| --- | --- | --- |
| Create a new timesheet (you become its admin) | Yes | Yes |
| Join a timesheet with an invitation | Yes | Yes |
| Log, edit, remove and clone your own entries | Yes | Yes |
| See your totals, export your entries | Yes | Yes |
| Leave the timesheet | Yes | Yes |
| See and export the entries of other members | No | Yes |
| Change the name and the fields, delete the timesheet | No | Yes |
| Invite people, remove members, change roles | No | Yes |
| Manage periods, planned hours and statistics | No | Yes |

> **Note:** When you leave a timesheet or an admin removes you from it, your
> entries stay in the timesheet, you just can't use it any more. Deleting a
> timesheet deletes all its entries.

### Periods

A period is a time span, e.g. a semester, with the hours each member should
work in it. Its statistics show who is ahead and who is behind.

## More

- [Application functionality](../app-functionality.md) describes every
  feature in detail, for admins and developers.
- TimeTracker is released under the GPLv3 license.
