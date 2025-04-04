require 'rails_helper'

RSpec.describe TimeEntriesController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #entries' do
    it 'returns time entries for the user' do
      timesheet = create(:timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :entries, params: { timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end

    it 'returns a bad request if timesheet is not found' do
      get :entries, params: { timesheet_uuid: 'non_existent_uuid' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized if user does not have access to the timesheet' do
      other_user = create(:user)
      other_timesheet = create(:timesheet)
      sign_in other_user

      get :entries, params: { timesheet_uuid: other_timesheet.uuid }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns time entries as CSV if csv param is present' do
      timesheet = create(:timesheet, :with_fields)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :entries, params: { timesheet_uuid: timesheet.uuid, csv: true }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/octet-stream')
      expect(response.headers['Content-Disposition']).to match(/time-entries/)
    end
  end

  describe 'POST #edit' do
    it 'edits a time entry for the user' do
      timesheet = create(:timesheet, :with_fields)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      new_description = 'Updated Description'

      post :edit, params: { time_entry: { id: time_entry.id, fields: { description: new_description } }, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.single(time_entry.id).fields['description']).to eq(new_description)
    end

    it 'creates a new time entry if id is not provided' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      new_description = 'New Entry'

      post :edit, params: { time_entry: { fields: { description: new_description } }, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.single(TimeEntry.last.id).fields['description']).to eq(new_description)
    end

    it 'returns a bad request if timesheet is not found' do
      post :edit, params: { time_entry: { description: 'New Entry' }, timesheet_uuid: 'non_existent_uuid' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized if user does not have access to the timesheet' do
      other_user = create(:user)
      other_timesheet = create(:timesheet)
      create(:users_timesheet, user: other_user, timesheet: other_timesheet, role: 'admin')

      post :edit, params: { time_entry: { description: 'New Entry' }, timesheet_uuid: other_timesheet.uuid }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE #delete' do
    it 'deletes a time entry for the user' do
      timesheet = create(:timesheet)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)

      delete :delete, params: { id: time_entry.id }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.exists?(time_entry.id)).to be_falsey
    end

    it 'returns unauthorized if user does not have access to delete the time entry' do
      other_user = create(:user)
      timesheet = create(:timesheet)
      time_entry = create(:time_entry, user: other_user, timesheet: timesheet)
      create(:users_timesheet, user: other_user, timesheet: timesheet, role: 'user')

      delete :delete, params: { id: time_entry.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #popular' do
    it 'returns popular categories and projects for the user' do
      timesheet = create(:timesheet)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)

      get :popular

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #days' do
    it 'returns total hours by month day for the user' do
      timesheet = create(:timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :days, params: { month: '2023-09', timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #months' do
    it 'returns a list of time entries by month for the user' do
      timesheet = create(:timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :months, params: { timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #auto_complete' do
    it 'returns auto-complete suggestions for category or project' do
      timesheet = create(:timesheet, :with_fields)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)

      get :auto_complete, params: { field: 'category', term: 'search_term', timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
    end

    it 'returns a bad request if field or term is missing' do
      get :auto_complete

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns a bad request if field is invalid' do
      get :auto_complete, params: { field: 'invalid_field', term: 'search_term' }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
