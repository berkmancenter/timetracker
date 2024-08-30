class TimesheetFieldDataItem < ActiveRecord::Base
  belongs_to :time_entry
  belongs_to :timesheet_field, foreign_key: 'field_id'
end
