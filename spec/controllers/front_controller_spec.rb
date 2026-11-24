require 'rails_helper'

RSpec.describe FrontController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #index' do
    context 'when authenticated' do
      before do
        sign_in user
      end

      it 'renders the index_f.html page' do
        get :index
        page = File.read(Rails.root.join('public', 'index_f.html'))

        expect(response.body).to include(page.split('</head>').last)
        expect(response.media_type).to eq('text/html')
      end

      it 'tells the front-end how people sign in' do
        allow(Rails.application.config).to receive(:devise_auth_type).and_return('cas')

        get :index

        meta = Nokogiri::HTML(response.body).at('head meta[name="timetracker-auth-type"]')
        expect(meta['content']).to eq('cas')
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

  describe 'GET #ping' do
    it 'answers pong to a signed in user' do
      sign_in user

      get :ping

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('pong')
    end

    it 'redirects an unauthenticated user to sign in' do
      get :ping

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
