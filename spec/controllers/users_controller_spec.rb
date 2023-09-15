require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:superadmin_user) { create(:user, superadmin: true) }
  let(:regular_user) { create(:user) }

  before do
    sign_in superadmin_user
  end

  describe 'GET #index' do
    it 'returns a list of users' do
      user1 = create(:user, username: 'user1')
      user2 = create(:user, username: 'user2')

      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).map { |user| user['username'] }).to include('user1', 'user2')
    end
  end

  describe 'POST #delete' do
    it 'deletes selected users' do
      user_to_delete = create(:user)
      user_to_keep = create(:user)

      post :delete, params: { users: [user_to_delete.id] }
      expect(response).to have_http_status(:ok)
      expect(User.exists?(user_to_delete.id)).to be false
      expect(User.exists?(user_to_keep.id)).to be true
    end

    it 'returns an error message if no users are selected' do
      post :delete, params: { users: [] }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'No users selected.' })
    end
  end

  describe 'POST #toggle_admin' do
    it 'toggles admin status for selected users' do
      regular_user_1 = create(:user, superadmin: false)
      regular_user_2 = create(:user, superadmin: false)

      post :toggle_admin, params: { users: [regular_user_1.id] }
      expect(response).to have_http_status(:ok)
      expect(User.find(regular_user_1.id).superadmin).to be true
      expect(User.find(regular_user_2.id).superadmin).to be false
    end

    it 'returns an error message if no users are selected' do
      post :toggle_admin, params: { users: [] }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'No users selected.' })
    end
  end

  describe 'POST #sudo' do
    it 'sets sudo users in the session' do
      user_1 = create(:user)
      user_2 = create(:user)
      user_3 = create(:user)

      post :sudo, params: { users: [user_1.id, user_2.id] }
      expect(response).to have_http_status(:ok)
      expect(session["#{superadmin_user.id}_active_users"]).to eq([user_1.id.to_s, user_2.id.to_s])
    end
  end

  describe 'GET #current_user_data' do
    it 'returns data for the current user' do
      get :current_user_data
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data['username']).to eq(superadmin_user.username)
      expect(data['user_id']).to eq(superadmin_user.id)
      expect(data['is_superadmin']).to eq(true)
      expect(data['sudo_users']).to eq([])
    end
  end
end
