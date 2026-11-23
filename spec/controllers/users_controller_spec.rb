require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:superadmin_user) { create(:user, superadmin: true) }
  let(:regular_user) { create(:user) }
  let(:timesheet) { create(:timesheet) }

  describe 'POST #sudo' do
    before do
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'admin')
      sign_in regular_user
    end

    it 'allows sudo for selected users on a timesheet' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user)
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'user')

      post :sudo, params: { timesheet_id: timesheet.id, users: [user1.id, user2.id, user3.id] }

      expect(response).to have_http_status(:ok)
      expect(session["#{regular_user.id}_active_users"]).to eq(
        'timesheet_id' => timesheet.id,
        'user_ids' => [user1.id, user2.id]
      )
    end

    it 'returns a bad request if timesheet is not found' do
      user1 = create(:user)
      post :sudo, params: { timesheet_id: 'non_existent_id', users: [user1.id] }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized if user is not an admin for the timesheet' do
      user1 = create(:user)
      sign_in user1

      post :sudo, params: { timesheet_id: timesheet.id, users: [regular_user.id] }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #unsudo' do
    before do
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'admin')
      sign_in regular_user
    end

    it 'revokes sudo privileges for the current user' do
      user1 = create(:user)
      session["#{regular_user.id}_active_users"] = {
        'timesheet_id' => timesheet.id,
        'user_ids' => [user1.id]
      }

      post :unsudo

      expect(response).to have_http_status(:ok)
      expect(session["#{regular_user.id}_active_users"]).to be_nil
    end
  end

  describe 'GET #current_user_data' do
    it 'returns data for the current user' do
      sign_in superadmin_user
      get :current_user_data

      data = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(data['username']).to eq(superadmin_user.email)
      expect(data['user_id']).to eq(superadmin_user.id)
      expect(data['is_superadmin']).to eq(true)
      expect(data['sudo_users']).to eq([])
    end

    it 'returns the users selected with sudo' do
      sign_in regular_user
      session["#{regular_user.id}_active_users"] = { 'timesheet_id' => timesheet.id, 'user_ids' => ['5', 7] }

      get :current_user_data

      expect(response.parsed_body).to include(
        'username' => regular_user.email,
        'is_superadmin' => false,
        'sudo_users' => [5, 7]
      )
    end

    it 'ignores a selection in a wrong format' do
      sign_in regular_user
      session["#{regular_user.id}_active_users"] = 'not a selection'

      get :current_user_data

      expect(response.parsed_body['sudo_users']).to eq([])
    end

    it 'returns unauthorized when not signed in' do
      get :current_user_data

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq('message' => 'Unauthorized')
    end
  end

  describe 'POST #sudo access' do
    let(:member) { create(:user) }

    before do
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    end

    it 'lets a superadmin select users of any timesheet' do
      sign_in superadmin_user

      post :sudo, params: { timesheet_id: timesheet.id, users: [member.id] }

      expect(response).to have_http_status(:ok)
      expect(session["#{superadmin_user.id}_active_users"]).to eq(
        'timesheet_id' => timesheet.id,
        'user_ids' => [member.id]
      )
    end

    it 'does not let a regular member select users' do
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'user')
      sign_in regular_user

      post :sudo, params: { timesheet_id: timesheet.id, users: [member.id] }

      expect(response).to have_http_status(:unauthorized)
      expect(session["#{regular_user.id}_active_users"]).to be_nil
    end

    it 'saves an empty selection when no users are given' do
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'admin')
      sign_in regular_user

      post :sudo, params: { timesheet_id: timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(session["#{regular_user.id}_active_users"]['user_ids']).to eq([])
    end

    it 'returns unauthorized when not signed in' do
      post :sudo, params: { timesheet_id: timesheet.id, users: [member.id] }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #unsudo of one user' do
    it 'keeps the selections of other users' do
      sign_in regular_user
      session["#{regular_user.id}_active_users"] = { 'timesheet_id' => timesheet.id, 'user_ids' => [1] }
      session["#{superadmin_user.id}_active_users"] = { 'timesheet_id' => timesheet.id, 'user_ids' => [2] }

      post :unsudo

      expect(session["#{regular_user.id}_active_users"]).to be_nil
      expect(session["#{superadmin_user.id}_active_users"]).to be_present
    end
  end

  describe 'GET #index' do
    before do
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'admin')
      sign_in regular_user
    end

    it 'returns the members of the timesheet' do
      member = create(:user, first_name: 'Ada', last_name: 'Lovelace')
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: create(:user), timesheet: create(:timesheet))

      get :index, params: { timesheet_id: timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['users']).to contain_exactly(
        { 'id' => regular_user.id, 'email' => regular_user.email, 'first_name' => nil, 'last_name' => nil },
        { 'id' => member.id, 'email' => member.email, 'first_name' => 'Ada', 'last_name' => 'Lovelace' }
      )
    end

    it 'returns a bad request for a missing timesheet' do
      get :index, params: { timesheet_id: 0 }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'DELETE #cas_logout' do
    it 'signs the user out and goes to the CAS logout page' do
      sign_in regular_user
      allow(Rails.application.config).to receive(:rack_cas)
        .and_return(ActiveSupport::OrderedOptions.new.merge!(server_url: 'https://cas.example.test'))

      delete :cas_logout

      expect(response).to redirect_to('https://cas.example.test/logout')
      expect(controller.current_user).to be_nil
    end
  end
end
