require 'rails_helper'

feature 'Timesheet users' do
  include IntegrationHelper

  scenario 'an admin changes a member role', js: true do
    admin_membership = signed_in_user_with_timesheet
    member = create(:user, email: 'member-role@example.com')
    membership = create(:users_timesheet, user: member, timesheet: admin_membership.timesheet, role: 'user')

    visit front_path("admin/timesheets/#{admin_membership.timesheet.id}/users")

    within(find('tr', text: member.email)) do
      find('[title="Change role"]').click
    end
    find('input[name="adminTimesheetUsersSetRole"][value="admin"]').click
    click_on 'Confirm'

    expect(page).to have_content('User role have been updated.')
    expect(membership.reload.role).to eq('admin')
  end

  scenario 'an admin removes a member', js: true do
    admin_membership = signed_in_user_with_timesheet
    member = create(:user, email: 'member-remove@example.com')
    membership = create(:users_timesheet, user: member, timesheet: admin_membership.timesheet, role: 'user')

    visit front_path("admin/timesheets/#{admin_membership.timesheet.id}/users")

    within(find('tr', text: member.email)) do
      find('[title="Remove user from timesheet"]').click
    end
    click_on 'Confirm'

    expect(page).to have_content('Users have been removed.')
    expect(page).not_to have_content(member.email)
    expect(UsersTimesheet.exists?(membership.id)).to be(false)
  end
end
