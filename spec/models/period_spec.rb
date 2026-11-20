require 'rails_helper'

RSpec.describe Period, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:from) }
    it { should validate_presence_of(:to) }

    it 'rejects a period ending before it starts' do
      period = build(:period, from: Date.new(2026, 11, 2), to: Date.new(2026, 11, 1))

      expect(period).not_to be_valid
      expect(period.errors[:to]).to include('must be on or after the start date')
    end
  end

  describe 'associations' do
    it { should have_many(:credits).dependent(:destroy).autosave(true) }
    it { should belong_to(:timesheet) }
  end

  describe 'get_stats' do
    let!(:timesheet) { create(:timesheet) }
    let!(:period) { create(:period, timesheet: timesheet) }
    let!(:user) { create(:user) }
    let!(:users_timesheet) { create(:users_timesheet, user: user, timesheet: timesheet, role: 'user') }
    let!(:time_entry) { create(:time_entry, user: user, timesheet: timesheet, entry_date: period.from + 1.day) }
    let!(:credit) { create(:credit, period: period, user: user) }

    it 'calculates statistics correctly' do
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

    it 'includes credited users who have no time entries' do
      time_entry.destroy!

      stats = period.get_stats

      expect(stats.pluck('user_id')).to include(user.id)
      expect(stats.find { |row| row['user_id'] == user.id }['total_hours']).to eq('0.00')
    end

    it 'uses zero progress for future periods without invalid percentages' do
      allow(Date).to receive(:current).and_return(period.from - 1.day)

      stats = period.get_stats

      expect(stats.first['should_hours']).to eq('0.00')
      expect(stats.first['balance_percent']).to eq('0.00')
    end
  end

  describe 'user_periods' do
    let!(:admin_user) { create(:user, superadmin: false) }
    let!(:non_admin_user) { create(:user, superadmin: false) }
    let!(:admin_period) { create(:period) }
    let!(:non_admin_period) { create(:period) }

    before do
      admin_period.timesheet.users_timesheets.create(user: admin_user, role: 'admin')
      non_admin_period.timesheet.users_timesheets.create(user: non_admin_user, role: 'user')
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

  describe '.admin_periods_for_timesheet' do
    it 'returns only periods belonging to the supplied timesheet' do
      period = create(:period)
      other_period = create(:period)

      expect(described_class.admin_periods_for_timesheet(period.timesheet)).to contain_exactly(period)
      expect(described_class.admin_periods_for_timesheet(period.timesheet)).not_to include(other_period)
    end
  end
end
