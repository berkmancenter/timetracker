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

  describe '.timesheet_periods' do
    it 'returns only the periods of the timesheet' do
      period = create(:period)
      second_period = create(:period, timesheet: period.timesheet)
      create(:period)

      expect(described_class.timesheet_periods(period.timesheet)).to contain_exactly(period, second_period)
    end
  end

  describe 'dates' do
    it 'can start and end on the same day' do
      expect(build(:period, from: Date.new(2026, 3, 4), to: Date.new(2026, 3, 4))).to be_valid
    end
  end

  describe 'custom fields' do
    let(:period) { create(:period) }

    it { should have_many(:custom_fields).dependent(:destroy) }

    it 'lists them by their order' do
      second = create(:custom_field, customizable: period, machine_name: 'second', order: 2)
      first = create(:custom_field, customizable: period, machine_name: 'first', order: 1)

      expect(period.custom_fields).to eq([first, second])
    end

    it 'can add and remove them with nested attributes' do
      field = create(:custom_field, customizable: period, machine_name: 'grant')

      period.update!(custom_fields_attributes: [
        { id: field.id, _destroy: '1' },
        { title: 'Funding source', input_type: 'text' }
      ])

      expect(period.reload.custom_fields.pluck(:machine_name)).to eq(['funding_source'])
      expect(CustomField.exists?(field.id)).to be(false)
    end
  end

  describe 'get_stats numbers' do
    include ActiveSupport::Testing::TimeHelpers

    let(:timesheet) { create(:timesheet) }
    let(:period) { create(:period, timesheet: timesheet, from: Date.new(2026, 11, 1), to: Date.new(2026, 11, 10)) }
    let(:member) { create(:user, username: 'member') }

    before do
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      create(:credit, user: member, period: period, amount: 20)
    end

    def add_member(username: nil, role: 'user', credit: 5)
      user = create(:user, username: username || Faker::Internet.unique.username(specifier: 10))
      create(:users_timesheet, user: user, timesheet: timesheet, role: role)
      create(:credit, user: user, period: period, amount: credit)
      user
    end

    def add_entry(date, hours, user: member, entry_timesheet: timesheet)
      create(:time_entry, user: user, timesheet: entry_timesheet, entry_date: date, decimal_time: hours)
    end

    def stats_row(user, user_ids = nil)
      period.get_stats(user_ids).find { |row| row['user_id'] == user.id }
    end

    it 'counts only entries of this timesheet between the period dates' do
      add_entry(Date.new(2026, 11, 1), 2)
      add_entry(Date.new(2026, 11, 10), 3)
      add_entry(Date.new(2026, 10, 31), 7)
      add_entry(Date.new(2026, 11, 11), 7)
      add_entry(Date.new(2026, 11, 5), 7, entry_timesheet: create(:timesheet))

      row = stats_row(member)

      expect(row['total_hours']).to eq('5.00')
      expect(row['last_entry_date']).to eq(Date.new(2026, 11, 10))
    end

    it 'has no last entry date for a user without entries' do
      expect(stats_row(member)['last_entry_date']).to be_nil
    end

    it 'expects all the credited hours after the period end' do
      travel_to Time.zone.local(2026, 12, 1, 12) do
        add_entry(Date.new(2026, 11, 3), 5)

        expect(stats_row(member)).to include(
          'credits' => '20.00',
          'total_hours' => '5.00',
          'should_hours' => '20.00',
          'balance' => '-15.00',
          'balance_percent' => '25.00'
        )
      end
    end

    it 'expects a part of the credited hours while the period runs' do
      travel_to Time.zone.local(2026, 11, 5, 12) do
        add_entry(Date.new(2026, 11, 2), 12)

        # 5 of 10 days are passed (the current day is counted)
        expect(stats_row(member)).to include(
          'should_hours' => '10.00',
          'balance' => '2.00',
          'balance_percent' => '120.00'
        )
      end
    end

    it 'counts the first day of the period as passed' do
      travel_to Time.zone.local(2026, 11, 1, 8) do
        expect(stats_row(member)['should_hours']).to eq('2.00')
      end
    end

    it 'leaves out members without a credit in this period' do
      no_credit = create(:user)
      create(:users_timesheet, user: no_credit, timesheet: timesheet, role: 'user')
      create(:credit, user: no_credit, period: create(:period, timesheet: timesheet))

      expect(period.get_stats.pluck('user_id')).to eq([member.id])
    end

    it 'leaves out credited users that are not members anymore' do
      former_member = create(:user)
      create(:credit, user: former_member, period: period)

      expect(period.get_stats.pluck('user_id')).to eq([member.id])
    end

    it 'orders the rows by username' do
      add_member(username: 'zoe')
      add_member(username: 'adam')

      expect(period.get_stats.pluck('username')).to eq(%w[adam member zoe])
    end

    it 'filters by a comma separated list of user ids' do
      other = add_member

      expect(period.get_stats(other.id.to_s).pluck('user_id')).to eq([other.id])
      expect(period.get_stats("#{member.id},#{other.id}").pluck('user_id')).to contain_exactly(member.id, other.id)
    end

    it 'marks the timesheet admins' do
      admin = add_member(role: 'admin')

      expect(stats_row(admin)).to include('admin' => true, 'roles' => ['admin'])
      expect(stats_row(member)).to include('admin' => false, 'roles' => ['user'])
    end

    it 'adds the period custom field values of every user' do
      grant = create(:custom_field, customizable: period, machine_name: 'grant', order: 1)
      room = create(:custom_field, customizable: period, machine_name: 'room', order: 2)
      other = add_member
      create(:custom_field_data_item, custom_field: grant, owner: member, value: 'NSF')

      expect(stats_row(member)).to include("custom_field_#{grant.id}" => 'NSF', "custom_field_#{room.id}" => '')
      expect(stats_row(other)).to include("custom_field_#{grant.id}" => '', "custom_field_#{room.id}" => '')
    end

    it 'does not add custom field keys when the period has no custom fields' do
      expect(stats_row(member).keys.grep(/\Acustom_field_/)).to be_empty
    end
  end
end
