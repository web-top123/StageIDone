class PagesController < ApplicationController
  skip_after_action :verify_authorized
  layout 'pages'

  def about
  end
end
