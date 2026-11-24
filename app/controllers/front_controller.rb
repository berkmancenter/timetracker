class FrontController < ApplicationController
  before_action :authenticate_user!, except: :ping
  before_action :authenticate_user_json!, only: :ping

  # GET /
  # Passes the request to the front-end
  def index
    render html: front_page.html_safe, layout: false
  end

  # GET /ping
  # The front-end calls it to check if the user is still signed in (401 when
  # not, no redirect to the sign in page) and which front-end the server has,
  # a different version means a new one was deployed.
  def ping
    render json: { version: front_version }
  end

  private

  # The front-end build is the same for every deployment, so the settings that
  # differ (how people sign in) are added to the page here.
  def front_page
    page = front_build
    settings = [
      helpers.tag.meta(name: 'timetracker-auth-type', content: Rails.application.config.devise_auth_type),
      helpers.tag.meta(name: 'timetracker-version', content: front_version(page))
    ]

    page.sub('</head>', "#{settings.join("\n")}\n</head>")
  end

  def front_build
    File.read(Rails.root.join('public', 'index_f.html'))
  end

  # Every build has other names of the front-end files in its page, so the
  # digest of the page tells the builds apart.
  def front_version(page = nil)
    Digest::SHA256.hexdigest(page || front_build).first(12)
  rescue Errno::ENOENT
    nil
  end
end
