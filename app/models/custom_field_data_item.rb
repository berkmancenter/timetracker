class CustomFieldDataItem < ActiveRecord::Base
  belongs_to :custom_field
  belongs_to :time_entry
  belongs_to :period
end
