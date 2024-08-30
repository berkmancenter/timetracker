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

  describe 'my_popular_categories' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:category_field) { create(:timesheet_field, machine_name: 'category', timesheet: timesheet, popular: true) }

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
    end

    it 'returns popular categories for the user' do
      popular = TimeEntry.popular(user)

      expect(popular['category']).to eq(['Category A', 'Category B', 'Category C'])
    end
  end

  describe 'my_popular_projects' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:project_field) { create(:timesheet_field, machine_name: 'project', timesheet: timesheet, popular: true) }

    before do
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

    it 'returns popular projects for the user' do
      popular = TimeEntry.popular(user)

      expect(popular['project']).to eq(['Project X', 'Project Y', 'Project Z'])
    end
  end

  describe 'my_entries_by_month' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }

    it 'returns TimeEntries for the user by month' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 2.months.ago)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 1.month.ago)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current)

      entries = TimeEntry.my_entries_by_month([user], "#{Time.current.year}-#{Time.current.strftime('%m')}", false, timesheet)

      expect(entries.length).to eq(1)
      expect(entries.first.user_id).to eq(user.id)
    end
  end

  describe 'total_hours_by_month_day' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:month) { "#{Time.current.year}-#{Time.current.strftime('%m')}" }

    date_1 = Date.today.beginning_of_month.days_since(9)
    date_2 = Date.today.beginning_of_month.days_since(8)
    date_3 = Date.today.beginning_of_month.days_since(7)

    it 'returns total hours by month and day for the user' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: date_1, decimal_time: 3.5)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: date_2, decimal_time: 2.0)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: date_3, decimal_time: 4.0)

      entries = TimeEntry.total_hours_by_month_day([user], month, timesheet)

      expect(entries.length).to eq(3)
    end

    it 'returns an empty array for nil month' do
      entries = TimeEntry.total_hours_by_month_day([user], nil, timesheet)
      expect(entries).to be_empty
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

      expect(entry_list).to include("#{Time.current.strftime('%Y')}-#{Time.current.strftime('%m')}")
      expect(entry_list).to include("#{1.month.ago.strftime('%Y')}-#{1.month.ago.strftime('%m')}")
    end
  end

  describe 'year_month' do
    let(:time_entry) { create(:time_entry, entry_date: Date.new(2023, 9, 15)) }

    it 'returns the year and month as a formatted string' do
      expect(time_entry.year_month).to eq('2023-09')
    end
  end
end
