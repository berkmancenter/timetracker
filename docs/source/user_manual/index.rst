###############
Getting started
###############

| Welcome to TimeTracker, a time tracking tracking solution for efficient and effortless management of your daily activities.
| This user manual is designed to guide you through the features and functionalities of TimeTracker.
| Whether you're a professional, freelancer, or student, TimeTracker is here to help you stay organized and focused on your priorities.

Timesheets
==========

* Timesheets serve as containers for time entries, providing a structured way to organize your activities.
* You can create as many timesheets as needed.
* You can invite other users to collaborate on your timesheets.
* You can grant admin privileges to users, allowing them to manage the timesheet as well.

Time entries
============

* Users can create, edit, remove their time entries.
* Required fields for time entries: ``Date``, ``Time spent``.

Timesheet user roles
====================

TimeTracker offers two user roles: ``user`` and ``admin``. The roles are scoped to timesheets, meaning that the permissions granted to users or admins apply specifically within the context of individual timesheets.

Users can:

* **Create timesheets**

  * Users can create new timesheets. When creating a timesheet, they are effectively added as an admin.

* **Create, edit, and remove time entries**

  * Users can create, edit, and remove time entries they've created within the timesheets they're associated with.

* **Act as admins on their timesheets**

  * Users can perform administrative functions on the timesheets they've created.

* **Join and leave timesheets**

  * Users can join other timesheets they've been invited to and leave timesheets as needed.

.. warning:: Removing or leaving timesheets will delete all time entries from that associated timesheet.

Admins can:

* **Perform all functions available to regular users**

  * Admins can perform all functions available to regular users within the timesheets they're associated with.
* **Manage timesheets they've been invited to**

  * Admins can manage (create, edit, remove) timesheets they've been invited to collaborate on.

* **Review time entries from other users**

  * Admins can review time entries submitted by other users within the timesheets they're associated with.

* **Invite other people as users or admins**

  * Admins can invite other users or admins to collaborate on the timesheets they've created.

.. note:: Modifying a user's role will apply only to the specific timesheet in question and will not impact their role in any other timesheets.

* **Create, edit, and remove periods**
  * Admins can create, edit, and remove periods of the timesheets they're associated with.

Periods
=======

* Periods offer a comprehensive way to access statistical data regarding timesheet usage by users within a specified timeframe.

License
=======

This application is released under a GPLv3 license.

.. toctree::
    :caption: User Manual
    :maxdepth: 2

    self

.. toctree::
    :titlesonly:

    UI explained <ui_explained>

.. toctree::
    :maxdepth: 2

    Managing time entries <managing_time_entries>

.. toctree::
    :maxdepth: 2

    Managing timesheets <managing_timesheets>

.. toctree::
    :maxdepth: 2

    Managing periods <managing_periods>

.. toctree::
    :maxdepth: 2

    Notes for Harvard users <for_harvard_users>

.. toctree::
    :caption: Technical
    :titlesonly:

    ../installation/index
    ../configuration/index
    ../development/index
