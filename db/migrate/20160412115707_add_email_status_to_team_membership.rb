class AddEmailStatusToTeamMembership < ActiveRecord::Migration
  def change
    add_column :team_memberships, :digest_status, :string
    add_column :team_memberships, :reminder_status, :string
  end
end
