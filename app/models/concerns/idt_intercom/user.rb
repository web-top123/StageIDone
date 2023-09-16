module IdtIntercom::User
  extend ActiveSupport::Concern
  included do
    after_create :send_to_intercom # create the user now
    after_update :queue_intercom, if: :user_details_changed? # queue updates to be processed in a batch
  end

  private
  def queue_intercom
    IntercomQueue.find_or_create_by(user_id: self.id)
  end

  def send_to_intercom
    IntercomUserWorker.perform_async(self.id)
  end

  def user_details_changed?
    self.full_name_changed?     ||
    self.email_address_changed? ||
    self.phone_number_changed?
  end
end
