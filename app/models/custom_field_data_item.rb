class CustomFieldDataItem < ApplicationRecord
  belongs_to :custom_field
  belongs_to :owner, polymorphic: true

  validates :owner_id, :owner_type, presence: true
  validates :custom_field_id, uniqueness: { scope: %i[owner_type owner_id] }
end
