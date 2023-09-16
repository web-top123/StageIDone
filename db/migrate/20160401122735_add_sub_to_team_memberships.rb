class AddSubToTeamMemberships < ActiveRecord::Migration
  def change
    add_column :team_memberships, :email_monday                          , :boolean , default: true
    add_column :team_memberships, :email_tuesday                         , :boolean , default: true
    add_column :team_memberships, :email_wednesday                       , :boolean , default: true
    add_column :team_memberships, :email_thursday                        , :boolean , default: true
    add_column :team_memberships, :email_friday                          , :boolean , default: true
    add_column :team_memberships, :email_saturday                        , :boolean , default: false
    add_column :team_memberships, :email_sunday                          , :boolean , default: false
    add_column :team_memberships, :email_digest_seconds_since_midnight   , :integer , default: 30600
    add_column :team_memberships, :email_reminder_seconds_since_midnight , :integer , default: 61200
    add_column :team_memberships, :email_digest_last_sent_at             , :datetime
    add_column :team_memberships, :email_reminder_last_sent_at           , :datetime
  end
end
