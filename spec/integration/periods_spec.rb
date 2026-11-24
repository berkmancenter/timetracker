require 'rails_helper'

feature 'Timesheet periods' do
  include IntegrationHelper

  scenario 'an admin creates and edits a period', js: true do
    membership = signed_in_user_with_timesheet
    timesheet = membership.timesheet

    visit front_path("admin/timesheets/#{timesheet.id}/periods/new")

    find('.admin-periods-form form > .field', text: 'Name').find('input').set('November reporting')
    find('.admin-periods-form form > .field', text: 'From').find('input').set('November 1, 2026')
    find('.admin-periods-form form > .field', text: 'To').find('input').set('November 30, 2026')
    click_on 'Save'

    expect(page).to have_content('Period has been saved.')
    expect(page).to have_content('November reporting')

    period = Period.find_by!(timesheet: timesheet, name: 'November reporting')
    expect(period).to have_attributes(from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 30))

    within(find('tr', text: period.name)) do
      find('[title="Edit period"]').click
    end
    expect(page).to have_content('Edit period')
    find('.admin-periods-form form > .field', text: 'Name').find('input').set('Updated November reporting')
    click_on 'Save'

    expect(page).to have_content('Period has been saved.')
    expect(page).to have_content('Updated November reporting')
    expect(period.reload.name).to eq('Updated November reporting')
  end

  scenario 'editing a period keeps its dates in time zones west of UTC', js: true do
    membership = signed_in_user_with_timesheet
    period = create(
      :period,
      timesheet: membership.timesheet,
      name: 'Fall period',
      from: Date.new(2026, 11, 1),
      to: Date.new(2026, 11, 30)
    )
    emulate_time_zone('America/New_York')

    visit front_path("admin/timesheets/#{membership.timesheet.id}/periods/#{period.id}/edit")

    within(find('.admin-periods-form form > .field', text: 'From')) do
      expect(page).to have_field(with: 'November 1, 2026')
    end
    within(find('.admin-periods-form form > .field', text: 'To')) do
      expect(page).to have_field(with: 'November 30, 2026')
    end
    click_on 'Save'

    expect(page).to have_content('Period has been saved.')
    expect(period.reload).to have_attributes(from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 30))
  end

  scenario 'a superadmin deletes a member entry in the period view and stays there', js: true do
    admin_membership = signed_in_user_with_timesheet
    admin_membership.user.update!(superadmin: true)
    timesheet = admin_membership.timesheet
    member = create(:user, email: 'reviewed-member@example.com')
    member_membership = create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    period = create(:period, timesheet: timesheet, from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 30))
    removed_entry = create_entry_with_project(member_membership, date: Date.new(2026, 11, 10), project: 'Removed project')
    create_entry_with_project(member_membership, date: Date.new(2026, 11, 11), project: 'Kept project')
    period_path = front_path("#{timesheet.uuid}/period/#{period.id}/user/#{member.id}")

    visit period_path

    find('.tracker-entries-entry', text: 'Removed project').click
    find('a[title="Delete entry"]').click
    click_on 'Confirm'

    expect(page).not_to have_selector('.tracker-entries-entry', text: 'Removed project')
    expect(page).to have_current_path(period_path)
    expect(page).to have_content('You are viewing time entries for the selected timesheet period and user.')
    expect(page).to have_selector('.tracker-entries-entry', text: 'Kept project')
    expect(TimeEntry.exists?(removed_entry.id)).to be(false)
  end

  scenario 'the period view does not offer to delete entries of other users', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    member = create(:user, email: 'other-member@example.com')
    member_membership = create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    period = create(:period, timesheet: timesheet, from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 30))
    create_entry_with_project(member_membership, date: Date.new(2026, 11, 10), project: 'Member project')

    visit front_path("#{timesheet.uuid}/period/#{period.id}/user/#{member.id}")

    find('.tracker-entries-entry', text: 'Member project').click

    # The menu opens a moment after the click, so wait for it a while
    expect { find('a[title="Delete entry"]', wait: 1) }.to raise_error(Capybara::ElementNotFound)
    expect(page).not_to have_selector('a[title="Edit entry"]')
  end

  scenario 'the period view loads the selected user and the timesheet', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    member = create(:user, email: 'period-user@example.com')
    member_membership = create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    period = create(:period, timesheet: timesheet, name: 'Loaded period', from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 30))
    create_entry_with_project(member_membership, date: Date.new(2026, 11, 12), project: 'Loaded project')

    visit front_path("#{timesheet.uuid}/period/#{period.id}/user/#{member.id}")

    within('.tracker-period-notification') do
      expect(page).to have_content('Test timesheet')
      expect(page).to have_content('Loaded period')
      expect(page).to have_content(member.email)
    end
    expect(page).to have_selector('.tracker-entries-entry', text: 'Loaded project')
    expect(page).to have_link('Go back to list period stats')
  end

  scenario 'statistics filters find users by the shown name and keep the role tab', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    admin_membership.user.update!(first_name: 'Alan', last_name: 'Turing')
    ada = create(:user, first_name: 'Ada', last_name: 'Lovelace', email: 'al@example.com')
    grace = create(:user, first_name: 'Grace', last_name: 'Hopper', email: 'gh@example.com')
    create(:users_timesheet, user: ada, timesheet: timesheet, role: 'user')
    create(:users_timesheet, user: grace, timesheet: timesheet, role: 'user')
    period = create(:period, timesheet: timesheet, from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 30))
    create(:credit, user: admin_membership.user, period: period, amount: 40)
    create(:credit, user: ada, period: period, amount: 35)
    create(:credit, user: grace, period: period, amount: 10)
    table = '.admin-periods-stats-table tbody'

    visit front_path("admin/timesheets/#{timesheet.id}/periods/#{period.id}/stats")

    # The "Users" tab is selected at the start, so the admin is not listed
    expect(page).to have_selector(table, text: 'Ada Lovelace')
    expect(page).not_to have_selector(table, text: 'Alan Turing')

    # The name is shown in the table, so it can be searched
    find('.tracker-action-button', text: 'Filter list').click
    find('input[placeholder="Search by identifier"]').set('lovelace')
    click_on 'Apply filters'

    expect(page).to have_selector(table, text: 'Ada Lovelace')
    expect(page).not_to have_selector(table, text: 'Grace Hopper')

    find('.tracker-action-button', text: 'Filter list').click
    click_on 'Reset Filters'
    find('.timetracker-period-stats-filter-form > .mt-2', exact_text: 'Hours').find('input[placeholder="Min"]').set('30')
    click_on 'Apply filters'

    # The filter keeps the "Users" tab
    expect(page).to have_selector(table, text: 'Ada Lovelace')
    expect(page).not_to have_selector(table, text: 'Grace Hopper')
    expect(page).not_to have_selector(table, text: 'Alan Turing')

    # And the tab keeps the filter
    find('.tabs a', text: 'All').click

    expect(page).to have_selector(table, text: 'Alan Turing')
    expect(page).to have_selector(table, text: 'Ada Lovelace')
    expect(page).not_to have_selector(table, text: 'Grace Hopper')
  end

  scenario 'an admin clones and removes a period', js: true do
    membership = signed_in_user_with_timesheet
    period = create(
      :period,
      timesheet: membership.timesheet,
      name: 'Original period',
      from: Date.new(2026, 10, 1),
      to: Date.new(2026, 10, 31)
    )

    visit front_path("admin/timesheets/#{membership.timesheet.id}/periods")

    within(find('tr', text: period.name)) do
      find('[title="Clone period"]').click
    end

    expect(page).to have_content('Period "Original period" has been cloned.')
    expect(page).to have_content('Original period clone')
    clone = Period.find_by!(timesheet: membership.timesheet, name: 'Original period clone')
    expect(clone).to have_attributes(from: period.from, to: period.to)

    within(find('tr', text: clone.name)) do
      find('[title="Delete period"]').click
    end
    click_on 'Confirm'

    expect(page).to have_content('Period has been removed.')
    expect(page).not_to have_content('Original period clone')
    expect(Period.exists?(clone.id)).to be(false)
  end

  scenario 'an admin assigns hours and period metadata to a member', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    member = create(:user, email: 'hours-member@example.com')
    create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    period = create(:period, timesheet: timesheet, name: 'Hours period')
    field = create(
      :custom_field,
      customizable: period,
      machine_name: 'department',
      title: 'Department'
    )

    visit front_path("admin/timesheets/#{timesheet.id}/periods/#{period.id}/credits")

    within(find('tr', text: member.email)) do
      find('.admin-periods-credits-table-hours input').set('37.5')
      find('.custom-field-cell input').set('Research')
    end
    find('.tracker-action-button', text: 'Save all visible').click

    expect(page).to have_content('Hours have been saved.')
    expect(Credit.find_by!(period: period, user: member).amount).to eq(37.5)
    expect(CustomFieldDataItem.find_by!(custom_field: field, owner: member).value).to eq('Research')
  end

  scenario 'an admin filters statistics and opens a member period in the tracker', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    included_member = create(:user, email: 'included-member@example.com')
    excluded_member = create(:user, email: 'excluded-member@example.com')
    create(:users_timesheet, user: included_member, timesheet: timesheet, role: 'user')
    create(:users_timesheet, user: excluded_member, timesheet: timesheet, role: 'user')
    period = create(
      :period,
      timesheet: timesheet,
      name: 'Statistics period',
      from: Date.new(2026, 11, 1),
      to: Date.new(2026, 11, 30)
    )
    create(:credit, user: included_member, period: period, amount: 40)
    create(:credit, user: excluded_member, period: period, amount: 20)
    entry = create(
      :time_entry,
      user: included_member,
      timesheet: timesheet,
      entry_date: Date.new(2026, 11, 10),
      decimal_time: 7.5
    )
    create(
      :time_entry,
      user: excluded_member,
      timesheet: timesheet,
      entry_date: Date.new(2026, 11, 11),
      decimal_time: 2
    )
    project_field = timesheet.custom_fields.find_by!(machine_name: 'project')
    create(:custom_field_data_item, custom_field: project_field, owner: entry, value: 'Integration project')

    visit front_path("admin/timesheets/#{timesheet.id}/periods/#{period.id}/stats")

    expect(page).to have_selector('.admin-periods-stats-table', text: included_member.email)
    expect(page).to have_selector('.admin-periods-stats-table', text: '7.50')

    find('.tracker-action-button', text: 'Filter list').click
    find('input[placeholder="Search by identifier"]').set('included-member')
    click_on 'Apply filters'

    expect(page).to have_selector('.admin-periods-stats-table', text: included_member.email)
    expect(page).not_to have_selector('.admin-periods-stats-table', text: excluded_member.email)

    within(find('.admin-periods-stats-table tbody tr', text: included_member.email)) do
      click
    end

    expect(page).to have_content('You are viewing time entries for the selected timesheet period and user.')
    expect(page).to have_content(included_member.email)
    expect(page).to have_selector('.tracker-entries-entry', text: 'Integration project')
    expect(page).to have_link('Go back to list period stats')
  end

  scenario 'statistics table headers do not overlap each other', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    member = create(:user, first_name: 'Jonas', last_name: 'Weber', email: 'jonas@demo.timetracker.test')
    create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    period = create(
      :period,
      timesheet: timesheet,
      name: 'Current term',
      from: Date.new(2026, 8, 1),
      to: Date.new(2026, 8, 31)
    )
    funding = create(:custom_field, customizable: period, machine_name: 'funding_source', title: 'Funding source')
    supervisor = create(:custom_field, customizable: period, machine_name: 'supervisor', title: 'Supervisor')
    create(:credit, user: member, period: period, amount: 136)
    create(:time_entry, user: member, timesheet: timesheet, entry_date: Date.new(2026, 8, 20), decimal_time: 80)
    create(:time_entry, user: member, timesheet: timesheet, entry_date: Date.new(2026, 8, 21), decimal_time: 72.5)
    create(:custom_field_data_item, custom_field: funding, owner: member, value: 'Department fellowship')
    create(:custom_field_data_item, custom_field: supervisor, owner: member, value: 'Maya Chen')

    visit front_path("admin/timesheets/#{timesheet.id}/periods/#{period.id}/stats")

    expect(page).to have_selector('.admin-periods-stats-table thead th', text: 'Supervisor')
    expect(page).to have_selector('.admin-periods-stats-table tbody td', text: 'Department fellowship')

    header_metrics = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.admin-periods-stats-table thead th')).map((th) => {
        const cellRect = th.getBoundingClientRect()
        const style = window.getComputedStyle(th)
        const range = document.createRange()
        range.selectNodeContents(th)
        const textRect = range.getBoundingClientRect()

        return {
          text: th.textContent.trim(),
          cellLeft: cellRect.left,
          cellRight: cellRect.right,
          paddingRight: parseFloat(style.paddingRight),
          textLeft: textRect.left,
          textRight: textRect.right,
          scrollWidth: th.scrollWidth,
          clientWidth: th.clientWidth,
        }
      })
    JS

    expect(header_metrics.length).to eq(9)
    header_metrics.each do |header|
      expect(header['textRight']).to be <= (header['cellRight'] - header['paddingRight'] + 1),
        "Header #{header['text'].inspect} overflows its cell content box: #{header.inspect}"
    end
    header_metrics.each_cons(2) do |left_header, right_header|
      expect(left_header['textRight']).to be < right_header['textLeft'],
        "Header #{left_header['text'].inspect} overlaps #{right_header['text'].inspect}: #{left_header.inspect} vs #{right_header.inspect}"
    end
  end
end
