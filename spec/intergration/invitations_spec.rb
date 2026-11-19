require 'rails_helper'

feature 'Timesheet invitations' do
  include IntegrationHelper

  scenario 'an admin invites several users with the selected role', js: true do
    membership = signed_in_user_with_timesheet

    visit front_path("admin/timesheets/#{membership.timesheet.id}/invite")

    find('textarea').set("first.invitee@example.com\nsecond.invitee@example.com")
    find('input[name="role"][value="admin"]').click
    click_on 'Send'

    expect(page).to have_content('Invitations have been sent out.')

    invitations = Invitation.where(timesheet: membership.timesheet).order(:email)
    expect(invitations.pluck(:email)).to eq(%w[first.invitee@example.com second.invitee@example.com])
    expect(invitations.pluck(:role).uniq).to eq(['admin'])
    expect(invitations.pluck(:sender_id).uniq).to eq([membership.user.id])
  end

  scenario 'an invited user joins the timesheet', js: true do
    sender_membership = signed_in_user_with_timesheet
    invitee = create(:user)
    invitation = create(
      :invitation,
      timesheet: sender_membership.timesheet,
      sender: sender_membership.user,
      used_by: nil,
      role: 'user'
    )

    sign_in invitee
    visit front_path("join/#{invitation.code}")

    expect(page).to have_content('You have joined successfully.')
    expect(page).to have_button('Add time entry')

    membership = UsersTimesheet.find_by(user: invitee, timesheet: sender_membership.timesheet)
    expect(membership&.role).to eq('user')
    expect(invitation.reload).to have_attributes(used: true, used_by_id: invitee.id)
  end
end
