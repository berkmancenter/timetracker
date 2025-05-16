class CustomField < ActiveRecord::Base
  belongs_to :customizable, polymorphic: true
  has_many :custom_field_data_items, foreign_key: 'custom_field_id', dependent: :destroy

  validates :machine_name, presence: true, uniqueness: { scope: :customizable }

  before_validation :set_machine_name

  private

  def set_machine_name
    self.machine_name = self.title.parameterize.underscore if machine_name.blank?
  end
end
