class ChangeDefaultSubscribedNotificationsForTeamMembership < ActiveRecord::Migration
   def up
    change_column_default :team_memberships, :subscribed_notifications, ["comment", "mention"]
  end

  def down
    change_column_default :team_memberships, :subscribed_notifications, []
  end
end
