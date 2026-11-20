class CustomFieldDataItem < ActiveRecord::Base
  belongs_to :custom_field
  belongs_to :owner, polymorphic: true

  validates :owner_id, :owner_type, presence: true
end
