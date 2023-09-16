module IdtIntercom::Invitation
  extend ActiveSupport::Concern
  included do
    after_create :queue_intercom_sender
    after_update :queue_intercom_invitee, if: :invitation_redeemed?
  end

  private
  def queue_intercom_sender
    IntercomQueue.find_or_create_by(user_id: sender_id)
  end

  def queue_intercom_invitee
    invitee = User.find_by_email_address(email_address)
    if invitee
      IntercomQueue.find_or_create_by(user_id: invitee.id)
    end
  end

  def invitation_redeemed?
    self.redeemed_at_changed?
  end
end
