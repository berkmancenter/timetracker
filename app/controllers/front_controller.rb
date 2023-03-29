class FrontController < ApplicationController
  def index
    render file: 'public/index_f.html', layout: false
  end
end
