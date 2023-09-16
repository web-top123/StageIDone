class IsEmailSendActiveToTeamMembership < ActiveRecord::Migration
  def change
    add_column :team_memberships, :is_email_send_active, :boolean , default: false, null: false
  end
end
