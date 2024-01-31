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

    it 'returns popular categories for the user' do
      create_list(:time_entry, 5, user: user, category: 'Category A')
      create_list(:time_entry, 3, user: user, category: 'Category B')
      create_list(:time_entry, 2, user: user, category: 'Category C')

      popular_categories = TimeEntry.my_popular_categories(user)

      expect(popular_categories).to include('Category A')
      expect(popular_categories).to include('Category B')
      expect(popular_categories).to include('Category C')
    end
  end

  describe 'my_popular_projects' do
    let(:user) { create(:user) }

    it 'returns popular projects for the user' do
      create_list(:time_entry, 5, user: user, project: 'Project X')
      create_list(:time_entry, 3, user: user, project: 'Project Y')
      create_list(:time_entry, 2, user: user, project: 'Project Z')

      popular_projects = TimeEntry.my_popular_projects(user)

      expect(popular_projects).to include('Project X')
      expect(popular_projects).to include('Project Y')
      expect(popular_projects).to include('Project Z')
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

    it 'returns total hours by month and day for the user' do
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 2.days.ago, decimal_time: 3.5)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 1.day.ago, decimal_time: 2.0)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 4.0)

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
