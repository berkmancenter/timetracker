class FrontController < ApplicationController
  before_action :authenticate_user!

  # GET /
  # Passes the request to the front-end
  def index
    render html: front_page.html_safe, layout: false
  end

  # GET /ping
  # Used by the front-end to check if the server is up and user is authenticated
  def ping
    render plain: 'pong'
  end

  private

  # The front-end build is the same for every deployment, so the settings that
  # differ (how people sign in) are added to the page here.
  def front_page
    page = File.read(Rails.root.join('public', 'index_f.html'))
    auth_type = helpers.tag.meta(name: 'timetracker-auth-type', content: Rails.application.config.devise_auth_type)

    page.sub('</head>', "#{auth_type}\n</head>")
  end
end
