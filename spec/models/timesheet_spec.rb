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
end
