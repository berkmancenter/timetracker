class FrontController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user_json!

  def index
    render file: 'public/index_f.html', layout: false
  end
end
