class CustomFieldDataItem < ActiveRecord::Base
  belongs_to :custom_field
  belongs_to :time_entry, class_name: 'TimeEntry', foreign_key: :item_id

  validates :item_id, presence: true
end
