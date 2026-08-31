require 'rails_helper'

RSpec.describe 'Header authentication', type: :request do
  around do |example|
    original_auth_type = Rails.application.config.devise_auth_type
    Rails.application.config.devise_auth_type = 'headers'
    example.run
  ensure
    Rails.application.config.devise_auth_type = original_auth_type
  end

  let(:headers) do
    {
      'X-Auth-Email' => 'Person@Example.com',
      'X-Auth-Name' => 'Proxy User',
    }
  end

  it 'creates a user from the trusted headers and authenticates the request' do
    expect do
      get timesheets_path, headers: headers
    end.to change(User, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(User.last).to have_attributes(
      email: 'person@example.com',
      first_name: 'Proxy',
      last_name: 'User'
    )
  end

  it 'updates the existing user matched by email' do
    user = create(
      :user,
      email: 'person@example.com',
      first_name: 'Old',
      last_name: 'Name'
    )

    expect do
      get timesheets_path, headers: headers
    end.not_to change(User, :count)

    expect(response).to have_http_status(:ok)
    expect(user.reload).to have_attributes(first_name: 'Proxy', last_name: 'User')
  end

  it 'requires the email header' do
    expect do
      get timesheets_path, headers: headers.except('X-Auth-Email')
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq('message' => 'Unauthorized')
  end

  it 'requires the name header' do
    expect do
      get timesheets_path, headers: headers.except('X-Auth-Name')
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq('message' => 'Unauthorized')
  end

  it 'does not reuse the header-authenticated user without headers' do
    get timesheets_path, headers: headers
    expect(response).to have_http_status(:ok)

    get timesheets_path
    expect(response).to have_http_status(:unauthorized)
  end

  it 'authenticates the front-end route from headers' do
    get root_path, headers: headers

    expect(response).to have_http_status(:ok)
  end

  it 'renders an authentication error page when front-end headers are missing' do
    get root_path

    expect(response).to have_http_status(:unauthorized)
    expect(response.body).to include('Authentication error')
    expect(response.body).to include('authentication service did not provide your identity')
  end
end
