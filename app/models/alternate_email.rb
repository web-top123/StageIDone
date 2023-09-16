class AlternateEmail < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  validates :email_address, presence: true, uniqueness: true
  validate  :email_address_does_not_belong_to_user

  before_create :generate_verification_code
  after_commit  :send_verification_email, on: :create

  def self.verified_user(email_address)
    self.where(["email_address = ? AND verified_at IS NOT NULL", email_address]).first.try(:user)
  end

  def verify!
    self.verification_code = nil
    self.verified_at = Time.zone.now
    self.save!
  end

  private
  def email_address_does_not_belong_to_user
    if self.email_address.present? && User.exists?(email_address: self.email_address)
      errors.add(:email_address, "cannot belong to an existing user")
    end
  end

  def generate_verification_code
    self.verification_code = SecureRandom.urlsafe_base64
  end

  def send_verification_email
    VerifyAlternateEmailWorker.perform_async(self.id)
  end
end
