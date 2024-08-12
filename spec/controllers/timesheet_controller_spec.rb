require 'rails_helper'

RSpec.describe TimesheetsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a list of user timesheets' do
      timesheet1 = create(:timesheet, name: 'Timesheet 1')
      timesheet2 = create(:timesheet, name: 'Timesheet 2')
      create(:users_timesheet, user: user, timesheet: timesheet1, role: 'admin')
      create(:users_timesheet, user: user, timesheet: timesheet2, role: 'user')

      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to match_array([
        { 'id' => timesheet1.id, 'name' => 'Timesheet 1', 'uuid' => timesheet1.uuid, 'roles' => ['admin'], 'created_at' => timesheet1.created_at.as_json },
        { 'id' => timesheet2.id, 'name' => 'Timesheet 2', 'uuid' => timesheet2.uuid, 'roles' => ['user'], 'created_at' => timesheet2.created_at.as_json }
      ])
    end

    it 'returns an empty list when the user has no timesheets' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns unauthorized when the user is not signed in' do
      sign_out user

      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end

    describe 'POST #upsert' do
    it 'creates a new timesheet' do
      expect do
        post :upsert, params: { timesheet: { name: 'New Timesheet' } }
      end.to change(Timesheet, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['timesheet']['name']).to eq('New Timesheet')
    end

    it 'updates an existing timesheet' do
      existing_timesheet = create(:timesheet, name: 'Existing Timesheet')
      create(:users_timesheet, user: user, timesheet: existing_timesheet, role: 'admin')

      post :upsert, params: { timesheet: { id: existing_timesheet.id, name: 'Updated Timesheet' } }

      existing_timesheet.reload
      expect(existing_timesheet.name).to eq('Updated Timesheet')
      expect(response).to have_http_status(:ok)
    end

    it 'returns a bad request if there are validation errors' do
      post :upsert, params: { timesheet: { name: nil } }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['message']).to include("Name can't be blank")
    end
  end

  describe 'DELETE #delete' do
    it 'deletes timesheets' do
      timesheet1 = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet1, role: 'admin')
      timesheet2 = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet2, role: 'admin')

      delete :delete, params: { timesheets: [timesheet1.id, timesheet2.id] }

      expect(response).to have_http_status(:ok)
      expect(Timesheet.where(id: [timesheet1.id, timesheet2.id])).to be_empty
    end

    it 'returns a bad request if the user is not authorized' do
      timesheet = create(:timesheet)
      sign_in create(:user)

      delete :delete, params: { timesheets: [timesheet.id] }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #send_invitations' do
    it 'sends invitations to specified emails with a valid role' do
      timesheet = create(:timesheet, name: 'Test Timesheet')
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      emails = 'test1@example.com, test2@example.com'
      emails_arr = ['test1@example.com', 'test2@example.com']
      valid_role = Invitation::VALID_ROLES.sample

      expect do
        post :send_invitations, params: { id: timesheet.id, emails: emails, role: valid_role }, format: :json
      end.to change(Invitation, :count).by(2)

      expect(response).to have_http_status(:ok)
      expect(Invitation.pluck(:email)).to match_array(emails_arr)
    end

    it 'returns unprocessable entity if no valid role is provided' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      emails = 'test1@example.com, test2@example.com'

      post :send_invitations, params: { id: timesheet.id, emails: emails, role: 'invalid_role' }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unauthorized if the user is not an admin' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
      emails = 'test1@example.com, test2@example.com'

      post :send_invitations, params: { id: timesheet.id, emails: emails }, format: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #join' do
    it 'allows a user to join a timesheet using a valid invitation code' do
      invitation = create(:invitation, used: false)

      post :join, params: { code: invitation.code }, format: :json

      invitation.reload
      expect(invitation.used).to be(true)
      expect(response).to have_http_status(:ok)
    end

    it 'returns bad request for an invalid invitation code' do
      post :join, params: { code: 'invalid_code' }, format: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'DELETE #leave' do
    it 'allows a user to leave a timesheet' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet)

      delete :leave, params: { id: timesheet.id }, format: :json

      expect(UsersTimesheet.where(user: user, timesheet: timesheet)).to be_empty
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #users' do
    let(:timesheet) { create(:timesheet) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'returns users for the timesheet for the admin user' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user3, timesheet: timesheet, role: 'user')

      get :users, params: { id: timesheet.id }

      expect(response).to have_http_status(:ok)
      response_parsed = JSON.parse(response.body)
      expect(response_parsed).to be_an(Array)
      expect(response_parsed.pluck('id')).to eq([user.id, user1.id, user2.id, user3.id])
    end

    it 'returns a bad request for non-admin user' do
      get :users, params: { id: timesheet.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #delete_users' do
    let(:timesheet) { create(:timesheet) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'deletes selected users from the timesheet for the admin user' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user3, timesheet: timesheet, role: 'user')

      post :delete_users, params: { id: timesheet.id, users: [user1.id, user2.id] }

      expect(response).to have_http_status(:ok)
      expect(User.where(id: timesheet.users.pluck(:id))).to eq(User.where(id: [user.id, user3.id]))
    end

    it 'returns a bad request if no users are selected' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      post :delete_users, params: { id: timesheet.id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized for non-admin user' do
      sign_out user
      sign_in user1

      post :delete_users, params: { id: timesheet.id, users: [user.id] }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #change_users_role' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      sign_in user
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'admin')
    end

    it 'changes users roles for the admin user' do
      user_ids = [user2.id]

      post :change_users_role, params: { id: timesheet.id, users: user_ids, role: 'user' }, format: :json

      expect(response).to have_http_status(:ok)
      expect(UsersTimesheet.where(user_id: user_ids, timesheet: timesheet).pluck(:role)).to eq(['user'])
    end

    it 'returns bad request if no users are selected' do
      post :change_users_role, params: { id: timesheet.id, role: 'user' }, format: :json

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized for non-admin user' do
      regular_user = create(:user)
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'user')

      sign_out user
      sign_in regular_user

      post :change_users_role, params: { id: timesheet.id, users: [user2.id], role: 'user' }, format: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
