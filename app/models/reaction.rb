class Reaction < ActiveRecord::Base
  include IdtIntercom::Reaction

  belongs_to :user, -> { with_deleted }
  belongs_to :reactable, polymorphic: true, touch: true

  has_many :mentions, as: :mentionable, dependent: :destroy

  has_many :tags, through: :reaction_tags
  has_many :reaction_tags, dependent: :destroy

  after_save :create_mentions
  after_save :save_reactions
  after_commit :send_notification, on: :create

  validates :user, presence: true
  validates :reactable, presence: true

  validates :body, presence: true, if: :comment?

  validates :reaction_type, inclusion: {in: %w(comment like)}

  scope :antichronologically, -> { order('reactions.created_at desc') }
  scope :chronologically, -> { order('reactions.created_at asc') }

  scope :is_comment, -> { where(reaction_type: 'comment') }
  scope :is_like, -> { where(reaction_type: 'like') }

  scope :for_period, -> (b,e) { where("reactions.created_at >= ? and reactions.created_at <= ?", b, e) }

  scope :for_team, -> (t) { all } # TODO: fredrik, please?
  scope :for_organization, -> (o) { all } # TODO: fredrik, please?

  # This is mostly around for migration purposes, we don't want to parse entities
  # when migrating old entries
  attr_accessor :skip_parsing_body

  def save_reactions
    return if skip_parsing_body
    entities   = EntryParser.extract_entities(body)
    tags       = entities.select{|e| !e[:hashtag].nil? }.map{|t| t[:hashtag].downcase }
    nicknames  = entities.select{|e| !e[:screen_name].nil? }.map{|n| n[:screen_name] }
    known_tags = Tag.where(name: tags)
    known_tag_names = known_tags.map(&:name)
    tags.each do |tag|
      unless known_tag_names.include?(tag)
        known_tags << Tag.create(name: tag.downcase)
        known_tag_names << tag
      end
    end
    known_tags.each do |known_tag|
      reaction_tags.find_or_create_by(tag: known_tag)
    end
    if !team.personal?
      nicknames.each do |nickname|
        user = team.active_users.where(go_by_name: nickname).first
        mentions.find_or_create_by(user: user) if user
      end
    end
  end

  def self.create_without_parsing(params)
    r = Reaction.new(params)
    r.skip_parsing_body = true
    r.save
    r
  end

  def team
    self.reactable.team
  end

  def comment?
    (reaction_type == 'comment')
  end

  def like?
    (reaction_type == 'like')
  end

  def create_mentions
    return if skip_parsing_body
    entities  = EntryParser.extract_entities(body)
    nicknames = entities.select{|e| !e[:screen_name].nil? }.map{|n| n[:screen_name] }
    if reactable.class == Entry && !reactable.team.personal?
      nicknames.each do |nickname|
        user = reactable.team.organization.active_users.where("full_name ILIKE ?", "%#{nickname}%").first
        mentions.find_or_create_by(user: user) if user
      end
    end
  end

  private

  def send_notification
    return if skip_parsing_body
    return true if self.user == self.reactable.user
    
    if self.comment?
      NotificationEmailWorker.perform_async(:comment, self.id)
    end

    if reactable_type == 'comment'
      notification_entry  = reactable.entry
    else
      notification_entry  = reactable
    end
    
    #add notifications for users, who subscribed for this types notifications 
    Notification.add(reactable.user,  notification_entry, "#{reaction_type}_on_#{reactable_type.downcase}", self.user)
    
    true
  end
end
