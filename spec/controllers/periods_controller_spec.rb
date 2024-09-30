require 'rails_helper'

RSpec.describe PeriodsController, type: :controller do
  let(:user) { create(:user) }
  let(:superadmin_user) { create(:user, superadmin: true) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a list of periods' do
      period = create_period

      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
      expect(JSON.parse(response.body).pluck('id')).to match_array([period.id])
    end

    it 'returns all periods for superadmin' do
      period1 = create_period(user)
      period2 = create_period(user)

      sign_out user
      sign_in superadmin_user

      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).pluck('id')).to match_array([period1.id, period2.id])
    end
  end

  describe 'GET #show' do
    it 'returns a specific period' do
      period = create_period

      get :show, params: { id: period.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(period.id)
    end
  end

  describe 'POST #upsert' do
    it 'creates a new period' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      post :upsert, params: { period: attributes_for(:period, timesheet_id: timesheet.id) }
      post :upsert, params: { period: attributes_for(:period, timesheet_id: timesheet.id) }

      expect(response).to have_http_status(:ok)
      expect(Period.count).to eq(2)
    end

    it 'updates an existing period' do
      period = create_period
      new_name = 'Updated Period'
      post :upsert, params: { period: attributes_for(:period, id: period.id, name: new_name) }

      expect(response).to have_http_status(:ok)
      expect(Period.find(period.id).name).to eq(new_name)
    end

    it 'returns a bad request if invalid data is provided' do
      post :upsert, params: { period: attributes_for(:period, timesheet_id: nil) }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'POST #delete' do
    it 'deletes selected periods' do
      period = create_period
      delete :delete, params: { periods: [period.id] }

      expect(response).to have_http_status(:ok)
      expect(Period.count).to eq(0)
    end

    it 'returns a bad request if no periods are selected' do
      delete :delete

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET #credits' do
    it 'returns credits for the period' do
      period = create_period
      create(:credit, user: user, period: period)
      get :credits, params: { id: period.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['credits']).to be_an(Array)
    end
  end

  describe 'POST #set_credits' do
    it 'sets credits for users in the period' do
      period = create_period
      post :set_credits, params: { id: period.id, credits: [{ user_id: user.id, credit_amount: 50.0 }] }

      expect(response).to have_http_status(:ok)
      expect(Credit.find_by(user: user, period: period).amount).to eq(50.0)
    end

    it 'returns a bad request if no users or credits are selected' do
      period = create_period
      post :set_credits, params: { id: period.id, credits: [] }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET #stats' do
    it 'returns statistics for the period' do
      period = create_period
      get :stats, params: { id: period.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('period')
      expect(JSON.parse(response.body)).to have_key('stats')
    end

    it 'returns statistics as CSV if csv param is present' do
      period = create_period
      get :stats, params: { id: period.id, csv: true }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/octet-stream')
      expect(response.headers['Content-Disposition']).to match(/statistics/)
    end
  end

  describe 'POST #clone' do
    it 'clones the period' do
      period = create_period
      post :clone, params: { id: period.id }

      expect(response).to have_http_status(:ok)
      expect(Period.count).to eq(2)
    end

    it 'returns a bad request if cloning fails' do
      period = create_period
      allow_any_instance_of(Period).to receive(:save).and_return(false)

      post :clone, params: { id: period.id }

      expect(response).to have_http_status(:bad_request)
    end
  end

  private

  def create_period(puser = user)
    timesheet = create(:timesheet)
    create(:users_timesheet, user: puser, timesheet: timesheet, role: 'admin')
    create(:period, timesheet: timesheet)
  end
end
