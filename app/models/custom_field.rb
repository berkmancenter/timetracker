class CustomField < ActiveRecord::Base
  belongs_to :customizable, polymorphic: true
  has_many :custom_field_data_items, dependent: :destroy

  validates :machine_name, presence: true, uniqueness: { scope: :customizable_id }

  before_validation :set_machine_name

  private

  def set_machine_name
    self.machine_name = self.title.parameterize.underscore if machine_name.blank?
  end
end
