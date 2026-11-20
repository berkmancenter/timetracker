require 'rails_helper'

RSpec.describe 'Time entries API', type: :request do
  around do |example|
    original_auth_type = Rails.application.config.devise_auth_type
    Rails.application.config.devise_auth_type = 'headers'
    example.run
  ensure
    Rails.application.config.devise_auth_type = original_auth_type
  end

  let(:headers) do
    {
      'X-Auth-Email' => 'api-user@example.com',
      'X-Auth-Name' => 'API User',
    }
  end

  let(:user) do
    get timesheets_path, headers: headers
    User.find_by!(email: 'api-user@example.com')
  end

  it 'creates, lists, and deletes an entry through the routed JSON API' do
    timesheet = create(:timesheet, :with_fields)
    create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

    expect do
      post edit_time_entries_path,
           params: {
             timesheet_uuid: timesheet.uuid,
             time_entry: {
               decimal_time: 2.5,
               entry_date: Date.current,
               fields: { project: 'Dependency refresh' }
             }
           },
           headers: headers,
           as: :json
    end.to change(TimeEntry, :count).by(1)

    expect(response).to have_http_status(:ok)
    entry = TimeEntry.last
    expect(response.parsed_body.fetch('fields')).to include('project' => 'Dependency refresh')

    get entries_time_entries_path,
        params: { timesheet_uuid: timesheet.uuid, month: 'all' },
        headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck('id')).to include(entry.id)

    expect do
      delete delete_time_entry_path(entry), headers: headers
    end.to change(TimeEntry, :count).by(-1)

    expect(response).to have_http_status(:ok)
  end

  it 'rejects entries for a timesheet the authenticated user cannot access' do
    timesheet = create(:timesheet)
    user

    get entries_time_entries_path,
        params: { timesheet_uuid: timesheet.uuid, month: 'all' },
        headers: headers

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq('message' => 'Unauthorized')
  end
end
