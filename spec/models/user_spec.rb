require 'rails_helper'

RSpec.describe User, type: :model do
  context 'associations' do
    it { should have_many(:time_entries).dependent(:destroy) }
    it { should have_many(:credits).dependent(:destroy) }
    it { should have_many(:users_timesheets).dependent(:destroy) }
    it { should have_many(:timesheets).through(:users_timesheets) }
  end

  context 'methods' do
    it 'should set the email attribute when CAS extra attributes are provided' do
      user = build(:user)
      user.cas_extra_attributes = { mail: 'cas@example.com' }
      expect(user.email).to eq('cas@example.com')
    end
  end
end
