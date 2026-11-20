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
end
