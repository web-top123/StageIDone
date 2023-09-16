module IdtIntercom::Organization
  extend ActiveSupport::Concern
  included do
    after_update :queue_intercom, if: :subscription_changed?
  end

  private
  def queue_intercom
    self.owners.each do |owner|
      IntercomQueue.find_or_create_by(user_id: owner.id)
    end
  end
end
