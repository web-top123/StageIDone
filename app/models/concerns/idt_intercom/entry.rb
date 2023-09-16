module IdtIntercom::Entry
  extend ActiveSupport::Concern
  included do
    after_create :queue_intercom
  end

  private
  def queue_intercom
    return if user_joined_more_than_two_weeks_ago
    IntercomQueue.find_or_create_by(user_id: user_id)
  end

  def user_joined_more_than_two_weeks_ago
    self.user.created_at < 14.days.ago
  end

end
