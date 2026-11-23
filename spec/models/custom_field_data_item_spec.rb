require 'rails_helper'

RSpec.describe CustomFieldDataItem, type: :model do
  describe 'associations' do
    it { should belong_to(:custom_field) }
    it { should belong_to(:owner) }
  end

  describe 'validations' do
    it { should validate_presence_of(:owner_id) }
    it { should validate_presence_of(:owner_type) }
  end

  it 'is removed when its time entry is removed' do
    time_entry = create(:time_entry)
    field = create(:custom_field, customizable: time_entry.timesheet)
    item = create(:custom_field_data_item, custom_field: field, owner: time_entry)

    expect { time_entry.destroy }.to change(described_class, :count).by(-1)
    expect(described_class.exists?(item.id)).to be(false)
  end

  it 'can belong to a user for period fields' do
    user = create(:user)
    field = create(:custom_field, customizable: create(:period))

    item = create(:custom_field_data_item, custom_field: field, owner: user, value: 'NSF')

    expect(item.reload.owner).to eq(user)
    expect(user.custom_field_data_items).to eq([item])
  end

  it 'is removed when its custom field is removed' do
    field = create(:custom_field, customizable: create(:timesheet))
    create(:custom_field_data_item, custom_field: field)

    expect { field.destroy }.to change(described_class, :count).by(-1)
  end

  it 'allows only one value per custom field and owner' do
    entry = create(:time_entry)
    field = create(:custom_field, customizable: entry.timesheet)
    item = create(:custom_field_data_item, custom_field: field, owner: entry)
    duplicate = build(:custom_field_data_item, custom_field: item.custom_field, owner: item.owner)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:custom_field_id]).to include('has already been taken')
  end
end
