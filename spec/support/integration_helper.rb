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
end
