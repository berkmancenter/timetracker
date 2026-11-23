require 'rails_helper'

RSpec.describe TimeEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:timesheet) }
  end

  describe 'validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:entry_date) }
    it { should validate_presence_of(:timesheet) }
  end

  describe 'popular' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:category_field) { create(:custom_field, machine_name: 'category', customizable: timesheet, popular: true) }
    let(:project_field) { create(:custom_field, machine_name: 'project', customizable: timesheet, popular: true) }

    before do
      # Create time entries with custom category field data
      create_list(:time_entry, 5, user: user, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field_id: category_field.id, value: 'Category A')
      end
      create_list(:time_entry, 3, user: user, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field_id: category_field.id, value: 'Category B')
      end
      create_list(:time_entry, 2, user: user, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field_id: category_field.id, value: 'Category C')
      end

      # Create time entries with custom project field data
      create_list(:time_entry, 5, user: user, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field_id: project_field.id, value: 'Project X')
      end
      create_list(:time_entry, 3, user: user, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field_id: project_field.id, value: 'Project Y')
      end
      create_list(:time_entry, 2, user: user, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field_id: project_field.id, value: 'Project Z')
      end
    end

    it 'returns popular categories and projects for the user' do
      popular = TimeEntry.popular(user)

      expect(popular['category']).to include('Category A', 'Category B', 'Category C')
      expect(popular['project']).to include('Project X', 'Project Y', 'Project Z')
    end
  end

  describe 'fetch_time_entries' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:month) { "#{Time.current.year}-#{Time.current.strftime('%m')}" }

    it 'returns TimeEntries for the user by month' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current)

      entries = TimeEntry.fetch_time_entries([user], {
        timesheet: timesheet,
        month: month
      })

      expect(entries.length).to eq(1)
      expect(entries.first.user_id).to eq(user.id)
    end

    it 'returns daily totals when group_by is day' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 3.5)

      entries = TimeEntry.fetch_time_entries([user], {
        timesheet: timesheet,
        month: month,
        group_by: 'day'
      })

      expect(entries.length).to eq(1)
      expect(entries.first[:total_hours]).to eq(3.5)
      expect(entries.first[:email]).to eq(user.email)
    end

    it 'returns weekly totals when group_by is week' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 3.5)

      entries = TimeEntry.fetch_time_entries([user], {
        timesheet: timesheet,
        month: month,
        group_by: 'week'
      })

      expect(entries.length).to eq(1)
      expect(entries.first[:total_hours]).to eq(3.5)
      expect(entries.first[:email]).to eq(user.email)
    end
  end

  describe 'entry_list_by_month' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }

    it 'returns a list of unique year-month entries for the user' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 2.months.ago)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 1.month.ago)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current)

      entry_list = TimeEntry.entry_list_by_month([user], timesheet)

      expect(entry_list).to include("#{Time.current.strftime('%Y-%m')}")
      expect(entry_list).to include("#{1.month.ago.strftime('%Y-%m')}")
      expect(entry_list).to include("#{2.months.ago.strftime('%Y-%m')}")
    end
  end

  describe 'total_hours_by_month' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:month) { "#{Time.current.year}-#{Time.current.strftime('%m')}" }

    it 'returns total hours for the user by month' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 3.5)

      total_hours = TimeEntry.total_hours_by_month([user], month, timesheet)

      expect(total_hours).to eq(3.5)
    end

    it 'returns 0 for nil month' do
      total_hours = TimeEntry.total_hours_by_month([user], nil, timesheet)
      expect(total_hours).to eq(0)
    end
  end

  describe 'total_hours_by_timesheet' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }

    it 'returns total hours for the user across all time' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 1.month.ago, decimal_time: 3.5)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 2.5)

      total_hours = TimeEntry.total_hours_by_timesheet([user], timesheet)

      expect(total_hours).to eq(6.0)
    end

    it 'returns 0 for nil timesheet' do
      total_hours = TimeEntry.total_hours_by_timesheet([user], nil)
      expect(total_hours).to eq(0)
    end
  end

  describe 'year_month' do
    let(:time_entry) { create(:time_entry, entry_date: Date.new(2023, 9, 15)) }

    it 'returns the year and month as a formatted string' do
      expect(time_entry.year_month).to eq('2023-09')
    end
  end

  describe '.single' do
    it 'returns nil without an id or for a missing entry' do
      expect(described_class.single(nil)).to be_nil
      expect(described_class.single(0)).to be_nil
    end

    it 'returns the entry with the user email and the custom field values' do
      timesheet = create(:timesheet, :with_fields)
      entry = create(:time_entry, timesheet: timesheet)
      create(:custom_field_data_item,
             owner: entry,
             custom_field: timesheet.custom_fields.find_by!(machine_name: 'project'),
             value: 'Apollo')

      single = described_class.single(entry.id)

      expect(single.email).to eq(entry.user.email)
      expect(single.fields).to eq('project' => 'Apollo')
      expect(single.as_json).to include('id' => entry.id, 'fields' => { 'project' => 'Apollo' })
    end
  end

  describe '#as_json' do
    it 'has the fields key also when fields are not loaded' do
      expect(create(:time_entry).as_json).to include('fields' => nil)
    end
  end

  describe 'popular values' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:project) { create(:custom_field, machine_name: 'project', customizable: timesheet, popular: true) }

    def add_value(field, value, owner: user, count: 1)
      create_list(:time_entry, count, user: owner, timesheet: field.customizable).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field: field, value: value)
      end
    end

    it 'returns an empty hash without a user' do
      expect(described_class.popular(nil)).to eq({})
    end

    it 'orders the values from the most used one' do
      add_value(project, 'Rare', count: 1)
      add_value(project, 'Often', count: 3)
      add_value(project, 'Sometimes', count: 2)

      expect(described_class.popular(user)['project']).to eq(%w[Often Sometimes Rare])
    end

    it 'uses only the entries of the given user' do
      add_value(project, 'Mine')
      add_value(project, 'Not mine', owner: create(:user), count: 5)

      expect(described_class.popular(user)).to eq('project' => ['Mine'])
    end

    it 'skips blank values and fields that are not popular' do
      add_value(project, '')
      add_value(create(:custom_field, machine_name: 'notes', customizable: timesheet, popular: false), 'Some notes')

      expect(described_class.popular(user)).to eq({})
    end

    it 'joins the values of popular fields with the same name from other timesheets' do
      other_project = create(:custom_field, machine_name: 'project', customizable: create(:timesheet), popular: true)
      add_value(project, 'First timesheet', count: 2)
      add_value(other_project, 'Second timesheet')
      add_value(other_project, 'First timesheet')

      expect(described_class.popular(user)['project']).to contain_exactly('First timesheet', 'Second timesheet')
    end

    it 'returns at most 20 values of a field' do
      25.times { |index| add_value(project, "Project #{index}") }

      expect(described_class.popular(user)['project'].size).to eq(20)
    end
  end

  describe 'fetch_time_entries options' do
    include ActiveSupport::Testing::TimeHelpers

    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }

    around do |example|
      travel_to(Time.zone.local(2026, 11, 20, 12)) { example.run }
    end

    def add_entry(date, hours = 1, owner: user, entry_timesheet: timesheet)
      create(:time_entry, user: owner, timesheet: entry_timesheet, entry_date: date, decimal_time: hours)
    end

    def fetch(users = [user], **options)
      described_class.fetch_time_entries(users, { timesheet: timesheet }.merge(options))
    end

    it 'returns an empty list or zero hours without a timesheet' do
      add_entry(Date.new(2026, 11, 2))

      expect(described_class.fetch_time_entries([user], {})).to eq([])
      expect(described_class.fetch_time_entries([user], { aggregate: 'sum_hours' })).to eq(0)
    end

    it 'returns an empty list or zero hours for an empty user selection' do
      add_entry(Date.new(2026, 11, 2))

      expect(fetch([], alltime: true)).to eq([])
      expect(fetch([], alltime: true, aggregate: 'sum_hours')).to eq(0)
    end

    it 'uses the current month when no month or dates are given' do
      current = add_entry(Date.new(2026, 11, 1))
      add_entry(Date.new(2026, 10, 31))
      add_entry(Date.new(2026, 12, 1))

      expect(fetch.map(&:id)).to eq([current.id])
    end

    it 'uses the given month' do
      october = add_entry(Date.new(2026, 10, 31))
      add_entry(Date.new(2026, 11, 1))

      expect(fetch(month: '2026-10').map(&:id)).to eq([october.id])
    end

    it 'returns entries of every month for all time' do
      entries = [add_entry(Date.new(2024, 1, 5)), add_entry(Date.new(2026, 11, 2))]

      expect(fetch(month: 'all', alltime: true).map(&:id)).to match_array(entries.map(&:id))
      expect(fetch(alltime: true).map(&:id)).to match_array(entries.map(&:id))
    end

    it 'prefers a date range over the month' do
      in_range = add_entry(Date.new(2026, 9, 15))
      add_entry(Date.new(2026, 9, 16))
      add_entry(Date.new(2026, 11, 2))

      entries = fetch(month: '2026-11', from_date: Date.new(2026, 9, 1), to_date: Date.new(2026, 9, 15))

      expect(entries.map(&:id)).to eq([in_range.id])
    end

    it 'leaves out entries of other timesheets and other users' do
      mine = add_entry(Date.new(2026, 11, 2))
      add_entry(Date.new(2026, 11, 2), entry_timesheet: create(:timesheet))
      add_entry(Date.new(2026, 11, 2), owner: create(:user))

      expect(fetch.map(&:id)).to eq([mine.id])
    end

    it 'returns entries of all the given users' do
      other = create(:user)
      entries = [add_entry(Date.new(2026, 11, 2)), add_entry(Date.new(2026, 11, 3), owner: other)]
      add_entry(Date.new(2026, 11, 4), owner: create(:user))

      expect(fetch([user, other]).map(&:id)).to match_array(entries.map(&:id))
    end

    it 'accepts a single user' do
      mine = add_entry(Date.new(2026, 11, 2))
      add_entry(Date.new(2026, 11, 2), owner: create(:user))

      expect(fetch(user).map(&:id)).to eq([mine.id])
    end

    it 'lists the newest entries first' do
      older = add_entry(Date.new(2026, 11, 2))
      newer_first = add_entry(Date.new(2026, 11, 5))
      newer_second = add_entry(Date.new(2026, 11, 5))

      expect(fetch.map(&:id)).to eq([newer_second.id, newer_first.id, older.id])
    end

    it 'adds the user email and the custom field values' do
      field = create(:custom_field, customizable: timesheet, machine_name: 'project')
      entry = add_entry(Date.new(2026, 11, 2))
      create(:custom_field_data_item, owner: entry, custom_field: field, value: 'Apollo')

      fetched = fetch.first

      expect(fetched.email).to eq(user.email)
      expect(fetched.fields).to eq('project' => 'Apollo')
    end

    it 'sums the hours' do
      add_entry(Date.new(2026, 11, 2), 1.25)
      add_entry(Date.new(2026, 11, 3), 2.5)
      add_entry(Date.new(2026, 10, 3), 8)

      expect(fetch(month: '2026-11', aggregate: 'sum_hours')).to eq(3.75)
      expect(fetch(alltime: true, aggregate: 'sum_hours')).to eq(11.75)
    end

    it 'sums zero hours when nothing matches' do
      expect(fetch(month: '2026-11', aggregate: 'sum_hours')).to eq(0.0)
    end

    it 'sums the hours of every user per day, newest day first' do
      other = create(:user)
      add_entry(Date.new(2026, 11, 2), 1.5)
      add_entry(Date.new(2026, 11, 2), 2)
      add_entry(Date.new(2026, 11, 3), 4)
      add_entry(Date.new(2026, 11, 2), 3, owner: other)

      result = fetch([user, other], month: '2026-11', group_by: 'day')

      expect(result).to contain_exactly(
        { date: '2026-11-03', total_hours: 4.0, email: user.email },
        { date: '2026-11-02', total_hours: 3.5, email: user.email },
        { date: '2026-11-02', total_hours: 3.0, email: other.email }
      )
      expect(result.first[:date]).to eq('2026-11-03')
    end

    it 'sums the hours per week, a week started in the month before counts from the first day' do
      add_entry(Date.new(2026, 10, 1), 1) # Thursday, the week started on Sunday 27 September
      add_entry(Date.new(2026, 10, 2), 2)
      add_entry(Date.new(2026, 10, 14), 4) # Wednesday

      result = fetch(month: '2026-10', group_by: 'week')

      expect(result).to contain_exactly(
        { date: '2026-10-01', total_hours: 3.0, email: user.email },
        { date: '2026-10-11', total_hours: 4.0, email: user.email }
      )
    end

    it 'sums the hours per week of a date range' do
      add_entry(Date.new(2026, 9, 30), 2) # Wednesday
      add_entry(Date.new(2026, 10, 1), 1)

      result = fetch(from_date: Date.new(2026, 9, 1), to_date: Date.new(2026, 10, 31), group_by: 'week')

      expect(result).to eq([{ date: '2026-09-27', total_hours: 3.0, email: user.email }])
    end
  end

  describe 'fetch_time_entries totals for all time' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }

    it 'returns only the last days and weeks' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current - 2, decimal_time: 1)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current - 60, decimal_time: 2)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current - 400, decimal_time: 4)

      days = described_class.fetch_time_entries([user], timesheet: timesheet, month: 'all', group_by: 'day')
      weeks = described_class.fetch_time_entries([user], timesheet: timesheet, month: 'all', group_by: 'week')

      expect(days.pluck(:total_hours)).to eq([1.0])
      expect(weeks.pluck(:total_hours)).to contain_exactly(1.0, 2.0)
    end
  end

  describe 'entry_list_by_month options' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }

    def add_entry(date, owner: user, entry_timesheet: timesheet)
      create(:time_entry, user: owner, timesheet: entry_timesheet, entry_date: date)
    end

    it 'returns an empty list without users or timesheet' do
      add_entry(Date.new(2026, 11, 2))

      expect(described_class.entry_list_by_month([], timesheet)).to eq([])
      expect(described_class.entry_list_by_month([user], nil)).to eq([])
    end

    it 'lists every month once, the newest first' do
      add_entry(Date.new(2026, 9, 2))
      add_entry(Date.new(2026, 11, 2))
      add_entry(Date.new(2026, 11, 20))
      add_entry(Date.new(2025, 12, 31))

      expect(described_class.entry_list_by_month([user], timesheet)).to eq(%w[2026-11 2026-09 2025-12])
    end

    it 'leaves out months of other users and other timesheets' do
      add_entry(Date.new(2026, 11, 2))
      add_entry(Date.new(2026, 10, 2), owner: create(:user))
      add_entry(Date.new(2026, 9, 2), entry_timesheet: create(:timesheet))

      expect(described_class.entry_list_by_month([user], timesheet)).to eq(['2026-11'])
    end

    it 'can be limited to a date range' do
      add_entry(Date.new(2026, 8, 31))
      add_entry(Date.new(2026, 9, 1))
      add_entry(Date.new(2026, 10, 15))
      add_entry(Date.new(2026, 10, 16))

      months = described_class.entry_list_by_month(
        [user], timesheet, from_date: Date.new(2026, 9, 1), to_date: Date.new(2026, 10, 15)
      )

      expect(months).to eq(%w[2026-10 2026-09])
    end
  end

  describe 'totals without users' do
    it 'returns zero' do
      timesheet = create(:timesheet)
      create(:time_entry, timesheet: timesheet, entry_date: Date.current)

      expect(described_class.total_hours_by_month([], Date.current.strftime('%Y-%m'), timesheet)).to eq(0)
      expect(described_class.total_hours_by_timesheet([], timesheet)).to eq(0)
    end
  end
end
