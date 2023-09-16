class AddSubscribedNotificationsToTeamMembership < ActiveRecord::Migration
  def change
    add_column :team_memberships, :subscribed_notifications, :string, array: true, default: []

    add_index :team_memberships, :subscribed_notifications

    TeamMembership.with_deleted.all.each do |team_membership|
      subs = if team_membership.subscribed
        ['mention', 'comment']
      else
        []
      end

      team_membership.update_column(:subscribed_notifications, subs)
    end
  end
end
