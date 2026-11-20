require 'rails_helper'

RSpec.describe UsersTimesheet, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:timesheet) }
  end


  describe 'validations' do
    it { should validate_inclusion_of(:role).in_array(%w[admin user]) }
  end
end
