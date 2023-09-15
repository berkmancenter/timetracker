require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def bad_request_action
      generic_bad_request_response
    end

    def unauthorized_action
      generic_unauthorized_response
    end
  end

  let(:user) { create(:user) }

  before do
    sign_in user

    @routes.draw do
      get '/bad_request_action', to: 'anonymous#bad_request_action'
      get '/unauthorized_action', to: 'anonymous#unauthorized_action'
      get '/ping', to: 'anonymous#ping'
    end
  end

  describe 'ping' do
    it 'returns "pong"' do
      get :ping
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('pong')
    end
  end

  describe 'generic_bad_request_response' do
    it 'returns a JSON response with status :bad_request' do
      get :bad_request_action
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'Bad request' })
    end
  end

  describe 'generic_unauthorized_response' do
    it 'returns a JSON response with status :unauthorized' do
      get :unauthorized_action
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'Unauthorized' })
    end
  end
end
