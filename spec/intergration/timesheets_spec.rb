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

    click_on 'Submit'

    expect(page).to have_content('Create new timesheets for yourself')
    expect(page).to have_content('Bright new timesheet')
  end
end
