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
    let(:category_field) { create(:timesheet_field, machine_name: 'category', timesheet: timesheet, popular: true) }
    let(:project_field) { create(:timesheet_field, machine_name: 'project', timesheet: timesheet, popular: true) }

    before do
      # Create time entries with custom category field data
      create_list(:time_entry, 5, user: user, timesheet: timesheet).each do |entry|
        create(:timesheet_field_data_item, time_entry: entry, field_id: category_field.id, value: 'Category A')
      end
      create_list(:time_entry, 3, user: user, timesheet: timesheet).each do |entry|
        create(:timesheet_field_data_item, time_entry: entry, field_id: category_field.id, value: 'Category B')
      end
      create_list(:time_entry, 2, user: user, timesheet: timesheet).each do |entry|
        create(:timesheet_field_data_item, time_entry: entry, field_id: category_field.id, value: 'Category C')
      end

      # Create time entries with custom project field data
      create_list(:time_entry, 5, user: user, timesheet: timesheet).each do |entry|
        create(:timesheet_field_data_item, time_entry: entry, field_id: project_field.id, value: 'Project X')
      end
      create_list(:time_entry, 3, user: user, timesheet: timesheet).each do |entry|
        create(:timesheet_field_data_item, time_entry: entry, field_id: project_field.id, value: 'Project Y')
      end
      create_list(:time_entry, 2, user: user, timesheet: timesheet).each do |entry|
        create(:timesheet_field_data_item, time_entry: entry, field_id: project_field.id, value: 'Project Z')
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
end
