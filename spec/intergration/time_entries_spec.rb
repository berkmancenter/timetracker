require 'rails_helper'

feature 'Timesheets' do
  include IntegrationHelper

  scenario 'adding time entry works', js: true do
    signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'World-takeover machine'
    fill_in 'Time spent', with: '5'
    click_on 'Add entry'

    expect(page).to have_selector '.tracker-entries-entry', text: 'World-takeover machine'
    expect(page).to have_selector '.tracker-entries-entry-decimal-time', text: '5.0'
  end

  scenario 'editing time entry works', js: true do
    signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'World-takeover machine'
    fill_in 'Time spent', with: '5'
    click_on 'Add entry'

    click_on 'Add time entry'
    fill_in 'Project', with: 'Time machine'
    fill_in 'Time spent', with: '10'
    click_on 'Add entry'

    page.find('.tracker-entries-entry', text: 'World-takeover machine').hover
    page.find('.tracker-entries-entry', text: 'World-takeover machine').find('.tracker-entries-entry-actions-dropdown').click
    page.find('a[title="Edit entry"]').click
    fill_in 'Time spent', with: '12'
    click_on 'Save changes'

    page.find('.tracker-entries-entry', text: 'Time machine').hover
    page.find('.tracker-entries-entry', text: 'Time machine').find('.tracker-entries-entry-actions-dropdown').click
    page.find('a[title="Edit entry"]').click
    fill_in 'Time spent', with: '2'
    click_on 'Save changes'

    expect(page.find('.tracker-entries-entry', text: 'World-takeover machine')).to have_selector '.tracker-entries-entry-decimal-time', text: '12.0'
    expect(page.find('.tracker-entries-entry', text: 'Time machine')).to have_selector '.tracker-entries-entry-decimal-time', text: '2'
  end

  scenario 'adding time doesn\'t work on missing time spent', js: true do
    signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'World-takeover machine'
    click_on 'Add entry'

    expect(page).not_to have_selector '.tracker-entries-entry-project', text: 'World-takeover machine'
  end

  scenario 'removing time entry works', js: true do
    signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'World-takeover machine'
    fill_in 'Time spent', with: '5'
    click_on 'Add entry'

    expect(page).to have_selector '.tracker-entries-entry', text: 'World-takeover machine'
    expect(page).to have_selector '.tracker-entries-entry-decimal-time', text: '5.0'

    page.find('.tracker-entries-entry', text: 'World-takeover machine').hover
    page.find('.tracker-entries-entry', text: 'World-takeover machine').find('.tracker-entries-entry-actions-dropdown').click
    page.find('a[title="Delete entry"]').click
    click_on 'Confirm'

    expect(page).not_to have_selector '.tracker-entries-entry', text: 'World-takeover machine'
  end

  scenario 'cloning time entry works', js: true do
    signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'World-takeover machine'
    fill_in 'Time spent', with: '5'
    click_on 'Add entry'

    expect(page).to have_selector '.tracker-entries-entry', text: 'World-takeover machine', count: 1
    expect(page).to have_selector '.tracker-entries-entry-decimal-time', text: '5.0', count: 1

    page.find('.tracker-entries-entry', text: 'World-takeover machine').hover
    page.find('.tracker-entries-entry', text: 'World-takeover machine').find('.tracker-entries-entry-actions-dropdown').click
    page.find('a[title="Clone entry"]').click
    click_on 'Add entry'

    expect(page).to have_selector '.tracker-entries-entry', text: 'World-takeover machine', count: 2
    expect(page).to have_selector '.tracker-entries-entry-decimal-time', text: '5.0', count: 2
  end
end
