require 'rails_helper'

RSpec.describe Timesheet, type: :model do
  describe 'associations' do
    it { should have_many(:time_entries).dependent(:destroy) }
    it { should have_many(:users_timesheets).dependent(:destroy) }
    it { should have_many(:users).through(:users_timesheets) }
    it { should have_many(:periods).dependent(:destroy) }
    it { should have_many(:invitations).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'admin?' do
    let(:timesheet) { create(:timesheet) }
    let(:superadmin) { create(:user, superadmin: true) }
    let(:admin_user) { create(:user) }
    let(:non_admin_user) { create(:user) }

    it 'returns true for superadmin users' do
      expect(timesheet.admin?(superadmin)).to be true
    end

    it 'returns true for admin users in the timesheet' do
      timesheet.users_timesheets.create(user: admin_user, role: 'admin')
      expect(timesheet.admin?(admin_user)).to be true
    end

    it 'returns false for non-admin users in the timesheet' do
      timesheet.users_timesheets.create(user: non_admin_user, role: 'user')
      expect(timesheet.admin?(non_admin_user)).to be false
    end
  end

  describe 'user?' do
    let(:timesheet) { create(:timesheet) }
    let(:superadmin) { create(:user, superadmin: true) }
    let(:user_user) { create(:user) }
    let(:admin_user) { create(:user) }
    let(:non_admin_user) { create(:user) }

    it 'returns true for superadmin users' do
      expect(timesheet.user?(superadmin)).to be true
    end

    it 'returns true for user users in the timesheet' do
      timesheet.users_timesheets.create(user: user_user, role: 'user')
      expect(timesheet.user?(user_user)).to be true
    end

    it 'returns true for admin users in the timesheet' do
      timesheet.users_timesheets.create(user: admin_user, role: 'admin')
      expect(timesheet.user?(admin_user)).to be true
    end

    it 'returns false for non-admin users not in the timesheet' do
      expect(timesheet.user?(non_admin_user)).to be false
    end
  end

  describe 'private methods' do
    describe 'set_uuid' do
      it 'sets the UUID if it is nil' do
        timesheet = create(:timesheet, uuid: nil)
        expect(timesheet.uuid).not_to be_nil
      end

      it 'does not change the UUID if it is already set' do
        uuid = SecureRandom.uuid
        timesheet = create(:timesheet, uuid: uuid)
        expect(timesheet.uuid).to eq(uuid)
      end
    end
  end

  describe 'access in another timesheet' do
    it 'does not make an admin of one timesheet an admin or user of another one' do
      user = create(:user)
      create(:users_timesheet, user: user, timesheet: create(:timesheet), role: 'admin')
      other_timesheet = create(:timesheet)

      expect(other_timesheet.admin?(user)).to be(false)
      expect(other_timesheet.user?(user)).to be(false)
    end
  end

  describe '#all_users' do
    it 'lists the members with their roles and join date' do
      timesheet = create(:timesheet)
      admin = create(:user)
      member = create(:user)
      create(:users_timesheet, user: admin, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: create(:user), timesheet: create(:timesheet))

      rows = timesheet.all_users.index_by(&:id)

      expect(rows.keys).to contain_exactly(admin.id, member.id)
      expect(rows[admin.id].roles).to eq(['admin'])
      expect(rows[member.id].roles).to eq(['user'])
      expect(rows[member.id].email).to eq(member.email)
      expect(rows[member.id].joined).to be_present
    end
  end

  describe 'custom fields' do
    let(:timesheet) { create(:timesheet) }

    it { should have_many(:custom_fields).dependent(:destroy) }

    it 'lists them by their order' do
      second = create(:custom_field, customizable: timesheet, machine_name: 'second', order: 2)
      first = create(:custom_field, customizable: timesheet, machine_name: 'first', order: 1)

      expect(timesheet.custom_fields).to eq([first, second])
    end

    it 'can add, change and remove them with nested attributes' do
      removed = create(:custom_field, customizable: timesheet, machine_name: 'removed')
      changed = create(:custom_field, customizable: timesheet, machine_name: 'changed', title: 'Old')

      timesheet.update!(custom_fields_attributes: [
        { id: removed.id, _destroy: '1' },
        { id: changed.id, title: 'New' },
        { title: 'Client name', input_type: 'text' }
      ])

      expect(timesheet.reload.custom_fields.pluck(:machine_name, :title)).to contain_exactly(
        %w[changed New], ['client_name', 'Client name']
      )
    end
  end

  describe 'removing' do
    it 'removes its entries, members, periods and invitations but not the users' do
      timesheet = create(:timesheet)
      user = create(:user)
      create(:users_timesheet, user: user, timesheet: timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:period, timesheet: timesheet)
      create(:invitation, timesheet: timesheet)

      timesheet.destroy!

      expect(UsersTimesheet.where(timesheet_id: timesheet.id)).to be_empty
      expect(TimeEntry.where(timesheet_id: timesheet.id)).to be_empty
      expect(Period.where(timesheet_id: timesheet.id)).to be_empty
      expect(Invitation.where(timesheet_id: timesheet.id)).to be_empty
      expect(User.exists?(user.id)).to be(true)
    end
  end
end
