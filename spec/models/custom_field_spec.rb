require 'rails_helper'

RSpec.describe CustomField, type: :model do
  describe 'associations' do
    it 'belongs to a polymorphic customizable record' do
      association = described_class.reflect_on_association(:customizable)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:polymorphic]).to be(true)
    end

    it { should have_many(:custom_field_data_items).dependent(:destroy) }
  end

  describe 'validations' do
    it 'requires a machine name after callbacks run' do
      field = build(:custom_field, title: '', machine_name: nil)

      expect(field).not_to be_valid
      expect(field.errors[:machine_name]).to be_present
    end

    it 'requires machine names to be unique within a customizable record' do
      timesheet = create(:timesheet)
      create(:custom_field, customizable: timesheet, machine_name: 'project')
      duplicate = build(:custom_field, customizable: timesheet, machine_name: 'project')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:machine_name]).to include('has already been taken')
    end

    it 'allows the same machine name on another customizable record' do
      create(:custom_field, customizable: create(:timesheet), machine_name: 'project')
      field = build(:custom_field, customizable: create(:timesheet), machine_name: 'project')

      expect(field).to be_valid
    end

    it 'allows the same machine name on a Timesheet and a Period with the same id' do
      timesheet = create(:timesheet)
      period = create(:period, id: timesheet.id)
      create(:custom_field, customizable: timesheet, machine_name: 'project')
      period_field = build(:custom_field, customizable: period, machine_name: 'project')

      expect(period_field).to be_valid
    end

    it 'handles a nil title without crashing' do
      field = build(:custom_field, title: nil, machine_name: nil)

      expect(field).not_to be_valid
      expect(field.errors[:machine_name]).to be_present
    end
  end

  describe 'machine name generation' do
    it 'generates a parameterized machine name from the title' do
      field = build(:custom_field, title: 'Client & Project', machine_name: nil)

      field.validate

      expect(field.machine_name).to eq('client_project')
    end

    it 'preserves a supplied machine name' do
      field = build(:custom_field, title: 'Client Project', machine_name: 'billing_code')

      field.validate

      expect(field.machine_name).to eq('billing_code')
    end
  end
end
