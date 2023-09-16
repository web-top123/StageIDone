class IntegrationsController < ApplicationController
  before_action :require_login

  def index
    authorize :integration
  end
end
