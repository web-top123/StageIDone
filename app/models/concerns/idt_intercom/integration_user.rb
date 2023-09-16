module IdtIntercom::IntegrationUser
  extend ActiveSupport::Concern
  included do
    after_create :queue_intercom
  end

  private
  def queue_intercom
    IntercomQueue.find_or_create_by(user_id: user_id)
  end
end
