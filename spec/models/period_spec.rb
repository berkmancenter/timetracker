require 'rails_helper'

RSpec.describe Period, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:from) }
    it { should validate_presence_of(:to) }
  end

  describe 'associations' do
    it { should have_many(:credits).dependent(:destroy).autosave(true) }
    it { should belong_to(:timesheet) }
  end

  describe 'get_stats' do
    let(:period) { create(:period) }
    let(:user) { create(:user) }
    let(:time_entry) { create(:time_entry, user: user, timesheet: period.timesheet, entry_date: period.from + 1.day) }
    let(:credit) { create(:credit, period: period, user: user) }

    it 'calculates statistics correctly' do
      time_entry
      credit.update(amount: 10.0)

      stats = period.get_stats

      expect(stats).to be_an(Array)
      expect(stats).not_to be_empty

      user_stats = stats.first
      expect(user_stats['user_id']).to eq(user.id)
      expect(user_stats['username']).to eq(user.username)
      expect(user_stats['email']).to eq(user.email)
      expect(user_stats['credits']).to eq('10.00')
    end
  end

  describe 'user_periods' do
    let(:admin_user) { create(:user, superadmin: false) }
    let(:non_admin_user) { create(:user, superadmin: false) }
    let(:admin_period) { create(:period) }
    let(:non_admin_period) { create(:period) }

    before do
      admin_period.timesheet.users_timesheets.create(user: admin_user, role: 'admin')
      non_admin_period.timesheet.users_timesheets.create(user: non_admin_user, role: 'member')
    end

    it 'returns periods for admin users' do
      admin_periods = Period.user_periods(admin_user)
      expect(admin_periods).to include(admin_period)
      expect(admin_periods).not_to include(non_admin_period)
    end

    it 'returns all periods for superadmin users' do
      superadmin_user = create(:user, superadmin: true)
      all_periods = Period.user_periods(superadmin_user)
      expect(all_periods).to include(admin_period, non_admin_period)
    end
  end
end
