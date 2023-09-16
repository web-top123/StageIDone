class AddDigestWeekToTeamMemberships < ActiveRecord::Migration
  def change
    add_column :team_memberships, :digest_monday                          , :boolean , default: true
    add_column :team_memberships, :digest_tuesday                         , :boolean , default: true
    add_column :team_memberships, :digest_wednesday                       , :boolean , default: true
    add_column :team_memberships, :digest_thursday                        , :boolean , default: true
    add_column :team_memberships, :digest_friday                          , :boolean , default: true
    add_column :team_memberships, :digest_saturday                        , :boolean , default: false
    add_column :team_memberships, :digest_sunday                          , :boolean , default: false
  end
end
