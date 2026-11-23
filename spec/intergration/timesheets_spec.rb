require 'rails_helper'

feature 'Timesheets' do
  include IntegrationHelper

  scenario 'index lists user timesheets', js: true do
    signed_in_user_with_timesheet

    visit front_path('admin/timesheets')

    expect(page).to have_content('Test timesheet')
  end

  scenario 'adding new timesheet works', js: true do
    signed_in_user_with_timesheet

    visit front_path('admin/timesheets/new')

    fill_in 'Name', with: 'Bright new timesheet'
    page.find('a[title="Add new field"]').click
    fill_in 'Title', with: 'Bright new field'
    click_on 'Submit'

    expect(page).to have_content('Create new timesheets for yourself')
    expect(page).to have_content('Bright new timesheet')
  end

  scenario 'removing timesheet works', js: true do
    signed_in_user_with_timesheet

    visit front_path('admin/timesheets')

    expect(page).to have_content('Test timesheet')

    page.find('a[title="Delete timesheet"]').click
    page.find('button', text: 'Confirm').click

    expect(page).not_to have_content('Test timesheet')
  end

  scenario 'editing timesheet works', js: true do
    signed_in_user_with_timesheet

    visit front_path('admin/timesheets')

    page.find('a[title="Edit timesheet"]').click

    fill_in 'Name', with: 'Updated timesheet'
    click_on 'Submit'

    expect(page).to have_content('Updated timesheet')
  end

  scenario 'leaving timesheet works', js: true do
    signed_in_user_with_timesheet

    visit front_path('admin/timesheets')

    expect(page).to have_content('Test timesheet')

    page.find('a[title="Leave timesheet"]').click
    page.find('button', text: 'Confirm').click

    expect(page).not_to have_content('Test timesheet')
  end

  scenario 'the browser back button to another timesheet shows the months of that timesheet', js: true do
    membership = signed_in_user_with_timesheet
    first_timesheet = membership.timesheet
    second_timesheet = create(:timesheet, :with_fields, name: 'Another timesheet')
    second_membership = create(:users_timesheet, user: membership.user, timesheet: second_timesheet, role: 'user')
    create_entry_with_project(membership, date: Date.new(2026, 10, 5), project: 'First October project')
    create_entry_with_project(membership, date: Date.new(2026, 11, 5), project: 'First November project')
    create_entry_with_project(second_membership, date: Date.new(2026, 9, 5), project: 'Second September project')

    visit front_path("#{first_timesheet.uuid}/2026-10")
    expect(page).to have_selector('.tracker-entries-entry', text: 'First October project')

    find('.side-menu-toggler').click
    find('.tracker-timesheets select').select('Another timesheet')

    expect(page).to have_current_path(%r{/#{second_timesheet.uuid}/2026-09})
    expect(page).to have_selector('.tracker-entries-entry', text: 'Second September project')

    page.go_back

    expect(page).to have_current_path(%r{/#{first_timesheet.uuid}/2026-10})
    expect(page).to have_button('2026-10')
    expect(page).to have_selector('.tracker-entries-entry', text: 'First October project')
  end

  scenario 'switching the active timesheet updates the tracker route', js: true do
    membership = signed_in_user_with_timesheet
    second_timesheet = create(:timesheet, :with_fields, name: 'Another timesheet')
    create(:users_timesheet, user: membership.user, timesheet: second_timesheet, role: 'user')

    visit front_path

    find('.side-menu-toggler').click
    find('.tracker-timesheets select').select('Another timesheet')

    expect(page).to have_current_path(%r{/#{second_timesheet.uuid}/})
    expect(find('.tracker-timesheets select').value).to eq(second_timesheet.id.to_s)
  end
end
