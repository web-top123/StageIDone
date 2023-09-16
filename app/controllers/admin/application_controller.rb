class Admin::ApplicationController < ApplicationController
  before_action :require_admin
  skip_after_action :verify_authorized
  layout 'admin'
end
