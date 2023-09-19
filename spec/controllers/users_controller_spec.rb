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
      expect(session["#{regular_user.id}_active_users"]).to eq([user1.id, user2.id])
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
      session["#{regular_user.id}_active_users"] = [user1.id]

      post :unsudo

      expect(response).to have_http_status(:ok)
      expect(session["#{regular_user.id}_active_users"]).to be_empty
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
  end
end
