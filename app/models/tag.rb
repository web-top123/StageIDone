class Tag < ActiveRecord::Base
  has_many :entries, through: :entry_tags
  has_many :entry_tags
  has_many :reactions, through: :reaction_tags
  has_many :reaction_tags

  before_save :ensure_downcased

  def to_param
    self.name
  end

  private

  def ensure_downcased
    self.name = name.downcase
  end
end
