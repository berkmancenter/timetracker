require 'rails_helper'

RSpec.describe UsersTimesheet, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:timesheet) }
  end
end
