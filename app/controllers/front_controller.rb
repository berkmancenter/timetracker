class FrontController < ApplicationController
  before_action :authenticate_user!

  def index
    sign_in(User.find(77))
    render file: 'public/index_f.html', layout: false
  end
end
