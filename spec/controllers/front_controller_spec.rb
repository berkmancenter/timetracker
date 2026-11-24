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

      it 'tells the front-end its version, the same one ping answers' do
        get :index
        meta = Nokogiri::HTML(response.body).at('head meta[name="timetracker-version"]')

        get :ping

        expect(meta['content']).to match(/\A\h{12}\z/)
        expect(response.parsed_body['version']).to eq(meta['content'])
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
    let(:page_path) { Rails.root.join('public', 'index_f.html') }

    it 'answers the version of the front-end to a signed in user' do
      sign_in user

      get :ping

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('version' => Digest::SHA256.hexdigest(File.read(page_path)).first(12))
    end

    it 'answers another version when the front-end was built again' do
      sign_in user
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(page_path).and_return('<html>first build</html>')
      get :ping
      first_version = response.parsed_body['version']

      allow(File).to receive(:read).with(page_path).and_return('<html>second build</html>')
      get :ping

      expect(response.parsed_body['version']).not_to eq(first_version)
    end

    it 'answers no version when the front-end is not built' do
      sign_in user
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(page_path).and_raise(Errno::ENOENT)

      get :ping

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('version' => nil)
    end

    it 'answers 401 to an unauthenticated user, without a redirect to sign in' do
      get :ping

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq('message' => 'Unauthorized')
    end
  end

  describe 'routes' do
    it 'sends pages of the front-end to it' do
      expect(get: '/admin/timesheets').to route_to('front#index', unmatched: 'admin/timesheets')
    end

    it 'does not send missing front-end files to the front-end page' do
      expect(get: '/front_assets/Tracker-old.js').not_to be_routable
    end
  end
end
