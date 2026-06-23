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

    it 'sets user attributes when SAML extra attributes are provided' do
      user = build(:user)
      user.saml_extra_attributes = {
        email: 'saml@example.com',
        givenName: 'Sam',
        sn: 'Login',
      }

      expect(user.email).to eq('saml@example.com')
      expect(user.first_name).to eq('Sam')
      expect(user.last_name).to eq('Login')
    end

    it 'uses a SAML display name when first and last names are not provided' do
      user = build(:user)
      user.saml_extra_attributes = {
        mail: 'display@example.com',
        displayName: 'Display User',
      }

      expect(user.email).to eq('display@example.com')
      expect(user.first_name).to eq('Display')
      expect(user.last_name).to eq('User')
    end
  end
end
