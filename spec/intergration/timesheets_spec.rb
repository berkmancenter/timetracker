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
end
