require 'rails_helper'

RSpec.describe FrontController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #index' do
    context 'when authenticated' do
      before do
        sign_in user
      end

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

    it 'redirects an unauthenticated user to sign in' do
      get :index

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
