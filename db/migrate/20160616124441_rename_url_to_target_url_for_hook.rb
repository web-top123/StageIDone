class RenameUrlToTargetUrlForHook < ActiveRecord::Migration
  def change
    rename_column :hooks, :url, :target_url
  end
end
