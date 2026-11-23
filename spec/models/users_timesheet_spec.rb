require 'rails_helper'

RSpec.describe UsersTimesheet, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:timesheet) }
  end


  describe 'validations' do
    it { should validate_inclusion_of(:role).in_array(%w[admin user]) }

    it 'allows a user only once in a timesheet' do
      membership = create(:users_timesheet, role: 'user')
      duplicate = build(:users_timesheet, user: membership.user, timesheet: membership.timesheet, role: 'admin')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:timesheet_id]).to include('has already been taken')
    end

    it 'allows the same user in another timesheet' do
      membership = create(:users_timesheet)

      expect(build(:users_timesheet, user: membership.user)).to be_valid
    end
  end

  it 'has the custom fields of its timesheet' do
    timesheet = create(:timesheet, :with_fields)
    membership = create(:users_timesheet, timesheet: timesheet)

    expect(membership.custom_fields.pluck(:machine_name)).to match_array(%w[category project description])
  end
end
