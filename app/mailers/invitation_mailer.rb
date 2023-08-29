class InvitationMailer < ApplicationMailer
  def send_invitation(timesheet, invitation)
    @invitation_link = "#{Timetracker::Application.config.front_url}/join/#{invitation.code}"
    @sender_email = invitation.sender.email
    @timesheet_name = timesheet.name

    mail(to: invitation.email, subject: "Invitation to \"#{timesheet.name}\"")
  end
end
