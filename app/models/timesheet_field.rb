class TimesheetField < ActiveRecord::Base
  belongs_to :timesheet
  has_many :timesheet_field_data_items, foreign_key: 'field_id', dependent: :destroy

  validates :machine_name, presence: true, uniqueness: { scope: :timesheet_id }

  before_validation :set_machine_name

  private

  def set_machine_name
    self.machine_name = self.title.parameterize.underscore if machine_name.blank?
  end
end
