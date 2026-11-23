require 'rails_helper'

RSpec.describe 'CSRF cookie', type: :request do
  it 'gives the front-end the CSRF token in a cookie' do
    sign_in create(:user)

    get timesheets_path

    expect(response).to have_http_status(:ok)
    expect(response.cookies['CSRF-TOKEN']).to be_present
  end

  context 'with header authentication' do
    around do |example|
      original_auth_type = Rails.application.config.devise_auth_type
      Rails.application.config.devise_auth_type = 'headers'
      example.run
    ensure
      Rails.application.config.devise_auth_type = original_auth_type
    end

    it 'does not set the cookie' do
      get timesheets_path, headers: { 'X-Auth-Email' => 'person@example.com', 'X-Auth-Name' => 'Proxy User' }

      expect(response).to have_http_status(:ok)
      expect(response.cookies).not_to have_key('CSRF-TOKEN')
    end
  end
end
