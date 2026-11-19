require 'rails_helper'

RSpec.describe InvitationMailer, type: :mailer do
  describe '#send_invitation' do
    it 'addresses the recipient and includes the sender, timesheet, and join link' do
      sender = create(:user, email: 'sender@example.com')
      timesheet = create(:timesheet, name: 'Research hours')
      invitation = create(
        :invitation,
        email: 'recipient@example.com',
        sender: sender,
        timesheet: timesheet
      )

      mail = described_class.send_invitation(timesheet, invitation)

      expect(mail.to).to eq(['recipient@example.com'])
      expect(mail.subject).to eq('Invitation to "Research hours"')
      expect(mail.body.encoded).to include('sender@example.com')
      expect(mail.body.encoded).to include('Research hours')
      expect(mail.body.encoded).to include("/join/#{invitation.code}")
    end
  end
end
