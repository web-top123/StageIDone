class AddNextSendDaysToDb < ActiveRecord::Migration
  def change
  	add_column :team_memberships, :next_reminder_time, :datetime
  	add_column :team_memberships, :next_digest_time, :datetime
    add_index :team_memberships, :next_reminder_time
    add_index :team_memberships, :next_digest_time
  end
end
