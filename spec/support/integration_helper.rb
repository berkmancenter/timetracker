module IntegrationHelper
  def signed_in_user_with_timesheet
    user = create(:user)
    sign_in user
    timesheet = create(:timesheet, :with_fields, name: 'Test timesheet')
    create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
  end

  def front_path(view = '')
    "#{root_path}#{view}"
  end

  # A time entry of the membership user with a value in the "project" field
  def create_entry_with_project(membership, date:, project:, hours: 1)
    project_field = membership.timesheet.custom_fields.find_by!(machine_name: 'project')
    entry = create(:time_entry, user: membership.user, timesheet: membership.timesheet, entry_date: date, decimal_time: hours)
    create(:custom_field_data_item, custom_field: project_field, owner: entry, value: project)

    entry
  end
end
