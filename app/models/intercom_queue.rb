class IntercomQueue < ActiveRecord::Base
  belongs_to :user, -> { with_deleted }

  def self.clear!
    IntercomQueue.where.not(processed_at: nil).delete_all
  end

  def mark_processed!
    touch(:processed_at)
  end
end
