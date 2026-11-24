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

    page.find('.tracker-entries-entry', text: 'World-takeover machine').click
    page.find('a[title="Edit entry"]').click
    fill_in 'Time spent', with: '12'
    click_on 'Save changes'

    page.find('.tracker-entries-entry', text: 'Time machine').click
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

    page.find('.tracker-entries-entry', text: 'World-takeover machine').click
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

    page.find('.tracker-entries-entry', text: 'World-takeover machine').click
    page.find('a[title="Clone entry"]').click
    click_on 'Add entry'

    expect(page).to have_selector '.tracker-entries-entry', text: 'World-takeover machine', count: 2
    expect(page).to have_selector '.tracker-entries-entry-decimal-time', text: '5.0', count: 2
  end

  scenario 'switching months shows entries from the selected month', js: true do
    membership = signed_in_user_with_timesheet
    timesheet = membership.timesheet
    project_field = timesheet.custom_fields.find_by!(machine_name: 'project')
    october_entry = create(
      :time_entry,
      user: membership.user,
      timesheet: timesheet,
      entry_date: Date.new(2026, 10, 5),
      decimal_time: 3
    )
    november_entry = create(
      :time_entry,
      user: membership.user,
      timesheet: timesheet,
      entry_date: Date.new(2026, 11, 6),
      decimal_time: 4
    )
    create(:custom_field_data_item, custom_field: project_field, owner: october_entry, value: 'October project')
    create(:custom_field_data_item, custom_field: project_field, owner: november_entry, value: 'November project')

    visit front_path("#{timesheet.uuid}/2026-11")

    expect(page).to have_selector('.tracker-entries-entry', text: 'November project')
    expect(page).not_to have_selector('.tracker-entries-entry', text: 'October project')

    find('[title="Select month"]').click
    find('.tracker-entries-months-selector-month', text: '2026-10').click

    expect(page).to have_current_path(%r{/#{timesheet.uuid}/2026-10})
    expect(page).to have_selector('.tracker-entries-entry', text: 'October project')
    expect(page).not_to have_selector('.tracker-entries-entry', text: 'November project')
  end

  scenario 'previous month goes to the older month and next month to the newer one', js: true do
    membership = signed_in_user_with_timesheet
    timesheet = membership.timesheet
    create_entry_with_project(membership, date: Date.new(2026, 9, 5), project: 'September project')
    create_entry_with_project(membership, date: Date.new(2026, 10, 5), project: 'October project')
    create_entry_with_project(membership, date: Date.new(2026, 11, 5), project: 'November project')

    visit front_path("#{timesheet.uuid}/2026-10")
    expect(page).to have_selector('.tracker-entries-entry', text: 'October project')

    click_on 'Previous month'

    expect(page).to have_current_path(%r{/#{timesheet.uuid}/2026-09})
    expect(page).to have_selector('.tracker-entries-entry', text: 'September project')
    expect(page).to have_button('Previous month', disabled: true)

    click_on 'Next month'
    expect(page).to have_current_path(%r{/#{timesheet.uuid}/2026-10})
    click_on 'Next month'

    expect(page).to have_current_path(%r{/#{timesheet.uuid}/2026-11})
    expect(page).to have_selector('.tracker-entries-entry', text: 'November project')
    expect(page).to have_button('Next month', disabled: true)
  end

  scenario 'a time entry which could not be saved keeps the form open with a warning', js: true do
    membership = signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'Refused project'
    fill_in 'Time spent', with: '2'

    # The user is removed from the timesheet while the form is open, so the API refuses the entry
    membership.destroy!
    click_on 'Add entry'

    expect(page).to have_content('The time entry could not be saved, try again.')
    expect(page).to have_field('Project', with: 'Refused project')
    expect(page).not_to have_selector('.timetracker-modal-buttons-confirm.running')
    expect(TimeEntry.count).to eq(0)
  end

  scenario 'pressing enter twice adds the time entry only once', js: true do
    signed_in_user_with_timesheet

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'Single project'
    fill_in 'Time spent', with: '3'
    find_field('Time spent').send_keys(:enter, :enter)

    expect(page).to have_selector('.tracker-entries-entry', text: 'Single project')
    expect(page).not_to have_field('Time spent')
    expect(page).to have_selector('.tracker-entries-entry', text: 'Single project', count: 1)
    expect(TimeEntry.count).to eq(1)
  end

  scenario 'a time with two decimals can be replaced by typing over it', js: true do
    membership = signed_in_user_with_timesheet
    entry = create_entry_with_project(membership, date: Date.current, project: 'Decimal project', hours: 1.25)

    visit front_path

    find('.tracker-entries-entry', text: 'Decimal project').click
    find('a[title="Edit entry"]').click
    find_field('Time spent', with: '1.25').send_keys([:control, 'a'], '2.5')

    expect(page).to have_field('Time spent', with: '2.5')
    click_on 'Save changes'

    expect(page).to have_selector('.tracker-entries-entry-decimal-time', text: '2.5')
    expect(entry.reload.decimal_time).to eq(2.5)
  end

  scenario 'the entry form keeps working after leaving the tracker and coming back', js: true do
    signed_in_user_with_timesheet
    collect_js_errors

    visit front_path

    click_on 'Add time entry'
    fill_in 'Project', with: 'First visit'
    fill_in 'Time spent', with: '1'
    click_on 'Add entry'
    expect(page).to have_selector('.tracker-entries-entry', text: 'First visit')

    2.times do
      find('.top-nav-button-menu', text: 'Timesheets').click
      expect(page).to have_content('Create new timesheets for yourself')
      find('.top-nav-button-menu', text: 'Time entries').click
      expect(page).to have_selector('.tracker-entries-entry', text: 'First visit')
    end

    click_on 'Add time entry'
    fill_in 'Project', with: 'Second visit'
    fill_in 'Time spent', with: '2'
    click_on 'Add entry'

    expect(page).to have_selector('.tracker-entries-entry', text: 'Second visit')
    expect(TimeEntry.count).to eq(2)
    expect(js_errors).to eq([])
  end

  scenario 'autocomplete finds values with special characters', js: true do
    membership = signed_in_user_with_timesheet
    create_entry_with_project(membership, date: Date.current, project: 'Plan #1')
    create_entry_with_project(membership, date: Date.current, project: 'Plan #2 & more')

    visit front_path

    click_on 'Add time entry'
    find_field('Project').send_keys('n #2 &')

    expect(page).to have_selector('.autocomplete div', exact_text: 'Plan #2 & more')
    expect(page).not_to have_selector('.autocomplete div', text: 'Plan #1')
  end

  scenario 'autocomplete shows values as text, not as HTML', js: true do
    membership = signed_in_user_with_timesheet
    create_entry_with_project(membership, date: Date.current, project: 'Tag <b>bold</b>')

    visit front_path

    click_on 'Add time entry'
    find_field('Project').click

    expect(page).to have_selector('.autocomplete div', exact_text: 'Tag <b>bold</b>')
    expect(page).not_to have_selector('.autocomplete b')
  end

  scenario 'closing the entry form removes its autocomplete listeners', js: true do
    signed_in_user_with_timesheet

    visit front_path

    open_and_close_form = lambda do
      click_on 'Add time entry'
      # The first field gets the focus after the autocomplete is set up
      expect(page).to have_selector('.tracker-entry-form input:focus')
      click_on 'Cancel'
      expect(page).not_to have_field('Time spent')
    end

    open_and_close_form.call
    listeners_after_first_close = window_event_listener_count('resize')
    3.times { open_and_close_form.call }

    expect(window_event_listener_count('resize')).to eq(listeners_after_first_close)
  end

  scenario 'switching months does not empty the list in between', js: true do
    membership = signed_in_user_with_timesheet
    create_entry_with_project(membership, date: Date.new(2026, 10, 5), project: 'October project')
    create_entry_with_project(membership, date: Date.new(2026, 11, 5), project: 'November project')

    visit front_path("#{membership.timesheet.uuid}/2026-11")
    expect(page).to have_selector('.tracker-entries-entry', text: 'November project')

    # Remembers the smallest number of entries the list ever had
    page.execute_script(<<~JS)
      window.smallestEntryCount = document.querySelectorAll('.tracker-entries-entry').length;
      new MutationObserver(() => {
        const count = document.querySelectorAll('.tracker-entries-entry').length;
        window.smallestEntryCount = Math.min(window.smallestEntryCount, count);
      }).observe(document.body, { childList: true, subtree: true });
    JS

    find('[title="Select month"]').click
    find('.tracker-entries-months-selector-month', text: '2026-10').click

    expect(page).to have_selector('.tracker-entries-entry', text: 'October project')
    expect(page.evaluate_script('window.smallestEntryCount')).to eq(1)
  end

  scenario 'a new entry gets the current date also when the page was opened the day before', js: true do
    signed_in_user_with_timesheet
    install_browser_clock

    visit front_path
    expect(page).to have_button('Add time entry')

    move_browser_clock(1.day)
    click_on 'Add time entry'

    tomorrow = page.evaluate_script(
      "new Intl.DateTimeFormat('en-US', { month: 'long', day: 'numeric', year: 'numeric' }).format(new Date())"
    )
    within('.tracker-entry-form .tracker-datepicker') do
      expect(page).to have_field(with: tomorrow)
    end
  end

  scenario 'an admin views another member entries and returns to their own entries', js: true do
    admin_membership = signed_in_user_with_timesheet
    timesheet = admin_membership.timesheet
    member = create(:user, email: 'tracked-member@example.com')
    create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    project_field = timesheet.custom_fields.find_by!(machine_name: 'project')
    entry = create(
      :time_entry,
      user: member,
      timesheet: timesheet,
      entry_date: Date.new(2026, 11, 7),
      decimal_time: 6
    )
    create(:custom_field_data_item, custom_field: project_field, owner: entry, value: 'Member project')

    visit front_path("#{timesheet.uuid}/2026-11")

    find('[title="View time entries of other users"]').click
    find('.tracker-entries-months-selector-user', text: member.email).click
    click_on 'Confirm'

    expect(page).to have_content('You are viewing time entries of other users.')
    expect(page).to have_selector('.tracker-entries-entry', text: 'Member project')
    expect(page).to have_selector('.tracker-entries-entry-email', text: member.email)

    find('a', text: 'Show only my entries').click

    expect(page).not_to have_content('You are viewing time entries of other users.')
    expect(page).not_to have_selector('.tracker-entries-entry', text: 'Member project')
  end
end
