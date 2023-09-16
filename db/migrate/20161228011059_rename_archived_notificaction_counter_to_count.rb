class RenameArchivedNotificactionCounterToCount < ActiveRecord::Migration
  def change
  	rename_column :archived_notifications, :counter, :count
  end
end
