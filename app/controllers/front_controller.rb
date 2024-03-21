class FrontController < ApplicationController
  before_action :authenticate_user!

  def index
    render file: 'public/index_f.html', layout: false
  end
end
