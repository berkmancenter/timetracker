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
end
