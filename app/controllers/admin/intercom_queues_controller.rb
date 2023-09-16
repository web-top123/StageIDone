class Admin::IntercomQueuesController < Admin::ApplicationController
  def index
    @scope_count = IntercomQueue.count
    @intercom_queues = IntercomQueue.page(params[:page])
  end
end
