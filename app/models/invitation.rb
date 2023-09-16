class Invitation < ActiveRecord::Base
  include IdtIntercom::Invitation

  belongs_to :organization
  belongs_to :team
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"

  validates :invitation_code, presence: true, uniqueness: true
  validates :email_address, presence: true, uniqueness: { scope: :organization_id, conditions: -> { where(declined_at: nil, redeemed_at: nil) } }

  before_validation :create_invitation_code
  before_validation :downcase_email
  after_save :send_invitation_if_unsent

  scope :antichronologically, -> { order('created_at desc') }
  scope :chronologically, -> { order('created_at asc') }
  scope :unredeemed, -> { where(redeemed_at: nil) }
  scope :redeemed, -> { where.not(redeemed_at: nil) }
  scope :undeclined, -> { where(declined_at: nil) }
  scope :sent, -> { where.not(sent_at: nil) }
  scope :for_team, -> (t) { where("'#{ t.id }' = ANY (team_ids)") }

  def first_name
    full_name.split(' ',2).first
  end

  def send_invitation!
    InvitationMailer.organization_invitation(self).deliver_now
    self.sent_at = Time.zone.now
    self.save!
  end

  def is_redeemed?
    self.redeemed_at.present?
  end

  def is_sent?
    self.sent_at.present?
  end

  def redeem_invitation!
    self.redeemed_at = Time.zone.now
    self.save!
  end

  def decline_invitation!
    touch(:declined_at)
    InvitationMailer.invitation_declined(self).deliver_now
  end

  def teams
    Team.find(self.team_ids)
  end

  def text
    t = self.teams.any? ? "#{self.teams.map(&:name).join(", ")}" : "#{self.organization.name}"
    t << " from #{sender.full_name}" if sender.present?    
    t << " on #{self.sent_at.to_date.to_s(:short)}"
  end

  private

  def create_invitation_code
    if self.new_record? ||  self.invitation_code.blank?
      self.invitation_code = Digest::SHA1.hexdigest([Time.now, rand].join)
    end
  end

  def send_invitation_if_unsent
    if !self.is_sent?
      self.send_invitation!
    end
  end

  def downcase_email
    self.email_address.downcase!
  end

end
