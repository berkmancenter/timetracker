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

    it 'reads CAS attributes whatever their case and skips the unknown ones' do
      user = build(:user, email: 'old@example.com')
      user.cas_extra_attributes = {
        'MAIL' => 'cas@example.com',
        'displayName' => ' Grace Brewster Hopper ',
        'department' => 'Navy',
      }

      expect(user).to have_attributes(email: 'cas@example.com', first_name: 'Grace', last_name: 'Hopper')
    end

    it 'uses the first value of multi-valued SAML attributes' do
      user = build(:user)
      user.saml_extra_attributes = {
        'mail' => ['first@example.com', 'second@example.com'],
        'given_name' => ['Ada'],
        'surname' => [],
        'sn' => ['Lovelace'],
      }

      expect(user).to have_attributes(email: 'first@example.com', first_name: 'Ada', last_name: 'Lovelace')
    end

    it 'takes from the SAML display name only the missing name part' do
      user = build(:user, first_name: nil, last_name: nil)
      user.saml_extra_attributes = { email: 'ada@example.com', first_name: 'Ada', displayName: 'Augusta Byron' }

      expect(user).to have_attributes(first_name: 'Ada', last_name: 'Byron')
    end

    it 'keeps the current values when SAML attributes are blank' do
      user = build(:user, email: 'keep@example.com', first_name: 'Keep', last_name: 'Me')
      user.saml_extra_attributes = { email: '', first_name: nil, last_name: [], displayName: ' ' }

      expect(user).to have_attributes(email: 'keep@example.com', first_name: 'Keep', last_name: 'Me')
    end
  end

  describe '#apply_saml_response' do
    def saml_response(values)
      response = double('SAML response')
      allow(response).to receive(:attribute_value_by_resource_key) { |key| values[key] }
      response
    end

    it 'sets the user attributes from the response' do
      user = build(:user)

      user.apply_saml_response(
        saml_response(email: ['saml@example.com'], first_name: 'Sam', last_name: 'Login'),
        'auth-value@example.com'
      )

      expect(user).to have_attributes(email: 'saml@example.com', first_name: 'Sam', last_name: 'Login')
    end

    it 'uses the auth value as email when the response has none' do
      user = build(:user)

      user.apply_saml_response(saml_response(display_name: 'Display Name'), 'auth-value@example.com')

      expect(user).to have_attributes(email: 'auth-value@example.com', first_name: 'Display', last_name: 'Name')
    end
  end

  describe '.from_auth_headers' do
    it 'creates a user with a lower case email and the name split in first and last' do
      user = described_class.from_auth_headers(email: ' New.Person@Example.com ', name: ' Ada  King Lovelace ')

      expect(user).to be_persisted
      expect(user).to have_attributes(email: 'new.person@example.com', first_name: 'Ada', last_name: 'Lovelace')
      expect(user.encrypted_password).to be_present
    end

    it 'finds the existing user whatever the email case' do
      existing = create(:user)
      existing.update_column(:email, 'Person@Example.com')

      user = nil
      expect do
        user = described_class.from_auth_headers(email: 'PERSON@example.COM', name: 'Proxy User')
      end.not_to change(described_class, :count)

      expect(user.id).to eq(existing.id)
      expect(existing.reload.email).to eq('person@example.com')
    end

    it 'uses a single word name as first and last name' do
      user = described_class.from_auth_headers(email: 'mononym@example.com', name: 'Zendaya')

      expect(user).to have_attributes(first_name: 'Zendaya', last_name: 'Zendaya')
    end

    it 'keeps the password of an existing user' do
      existing = create(:user, email: 'person@example.com')

      expect do
        described_class.from_auth_headers(email: 'person@example.com', name: 'Proxy User')
      end.not_to(change { existing.reload.encrypted_password })
    end
  end

  describe '#set_random_password' do
    it 'sets a password when the user has none' do
      user = described_class.new(email: 'new@example.com')

      user.set_random_password

      expect(user.encrypted_password).to be_present
      expect(user).to be_valid
    end

    it 'does not change an existing password' do
      user = create(:user, password: 'a-known-password')

      expect { user.set_random_password }.not_to change(user, :encrypted_password)
      expect(user.valid_password?('a-known-password')).to be(true)
    end
  end

  describe '#user_timesheets' do
    let(:user) { create(:user) }
    let!(:admin_timesheet) { create(:timesheet, name: 'Admin timesheet') }
    let!(:member_timesheet) { create(:timesheet, name: 'Member timesheet') }
    let!(:other_timesheet) { create(:timesheet, name: 'Other timesheet') }

    before do
      create(:users_timesheet, user: user, timesheet: admin_timesheet, role: 'admin')
      create(:users_timesheet, user: user, timesheet: member_timesheet, role: 'user')
      create(:users_timesheet, user: create(:user), timesheet: other_timesheet, role: 'admin')
    end

    it 'lists the timesheets of the user with the user roles' do
      rows = user.user_timesheets.map { |row| [row.name, row.roles] }

      expect(rows).to contain_exactly(['Admin timesheet', ['admin']], ['Member timesheet', ['user']])
    end

    it 'can list only the timesheets the user is admin of' do
      expect(user.user_timesheets(only_admin: true).map(&:name)).to eq(['Admin timesheet'])
    end

    it 'lists the timesheets of all users for a superadmin' do
      superadmin = create(:user, superadmin: true)

      expect(superadmin.user_timesheets.map(&:name)).to include(
        'Admin timesheet', 'Member timesheet', 'Other timesheet'
      )
      expect(superadmin.user_timesheets(only_admin: true).map(&:name)).to include('Member timesheet')
    end
  end

  describe '#superadmin?' do
    it 'tells if the user is a superadmin' do
      expect(build(:user, superadmin: true).superadmin?).to be(true)
      expect(build(:user, superadmin: false).superadmin?).to be(false)
    end
  end

  describe 'removing' do
    it 'removes the user custom field values' do
      user = create(:user)
      period = create(:period)
      create(:custom_field_data_item, custom_field: create(:custom_field, customizable: period), owner: user)

      expect { user.destroy! }.to change(CustomFieldDataItem, :count).by(-1)
    end
  end
end
