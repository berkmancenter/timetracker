require 'rails_helper'

RSpec.describe FrontController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'renders the index_f.html template' do
      get :index
      expect(response.body).to eq(File.read(Rails.root.join('public', 'index_f.html')))
    end

    it 'does not use a layout' do
      get :index
      expect(response).to render_template(layout: nil)
    end

    it 'returns a successful response' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end
